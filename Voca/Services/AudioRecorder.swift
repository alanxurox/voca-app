import AVFoundation
import CoreAudio
import Foundation

class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var isRecording = false
    private var tempURL: URL?

    private let sampleRate: Double = 16000
    private let channels: AVAudioChannelCount = 1

    // Audio level callback for visualization
    var onAudioLevel: ((Float) -> Void)?

    // Speech segment callback for incremental transcription
    var onSpeechSegment: (([Float]) -> Void)?

    // Silence detection parameters
    private let silenceThreshold: Float = 0.02  // RMS threshold for silence (increased for mic noise floor)
    private let silenceDuration: Double = 1.0   // Seconds of silence to trigger segment end (Brabble: 1.0s)
    private let minSpeechDuration: Double = 0.3 // Minimum speech duration to process (Brabble: 300ms for single words)
    private let maxSegmentDuration: Double = 10.0 // Force flush at silence after this duration (Brabble: 10s)
    private let minFinalFlushDuration: Double = 0.15 // Minimum speech duration for final flush (shorter to catch "thank you")

    // Speech segment tracking
    private var sampleBuffer: [Float] = []
    private var silenceStartTime: Date?
    private var speechStartTime: Date?
    private var isSpeaking = false
    private var actualSilenceSamples: Int = 0  // Track actual silence for dynamic removal

    // Smoothed RMS for stable visualization
    private var smoothedRMS: Float = 0
    private let smoothingFactor: Float = 0.3  // Lower = smoother, higher = more responsive

    func startRecording() {
        guard !isRecording else { return }

        // Reset state
        sampleBuffer = []
        silenceStartTime = nil
        speechStartTime = nil
        isSpeaking = false
        smoothedRMS = 0
        actualSilenceSamples = 0

        do {
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode

            // Create temp file for recording
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "voice_\(Date().timeIntervalSince1970).wav"
            tempURL = tempDir.appendingPathComponent(fileName)

            // Get input format and create output format (16kHz mono)
            let inputFormat = inputNode.outputFormat(forBus: 0)
            let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: channels,
                interleaved: false
            )!

            // Create audio file
            audioFile = try AVAudioFile(
                forWriting: tempURL!,
                settings: outputFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )

            // Create converter for resampling
            guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                print("Failed to create audio converter")
                return
            }

            // Install tap on input
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer, converter: converter, outputFormat: outputFormat)
            }

            try engine.start()
            audioEngine = engine
            isRecording = true

            print("Recording started...")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }

        audioEngine?.stop()  // Stop FIRST - flushes pending buffers
        audioEngine?.inputNode.removeTap(onBus: 0)  // Then remove tap
        
        // Wait for in-flight audio callbacks to complete (race condition fix)
        // The tap callback runs on audio render thread, needs time to flush last samples
        Thread.sleep(forTimeInterval: 0.05)  // 50ms
        
        audioEngine = nil
        audioFile = nil
        isRecording = false

        // Process any remaining speech in buffer with lower threshold for final flush
        let minFinalSamples = Int(sampleRate * minFinalFlushDuration)
        if !sampleBuffer.isEmpty && sampleBuffer.count > minFinalSamples {
            let samplesToKeep = max(0, sampleBuffer.count - actualSilenceSamples)
            let segment = Array(sampleBuffer.prefix(samplesToKeep))
            sampleBuffer = []
            actualSilenceSamples = 0
            if segment.count > minFinalSamples {
                print("📝 Flushing final segment: \(segment.count) samples (\(Double(segment.count) / sampleRate)s)")
                onSpeechSegment?(segment)
            }
        }

        print("Recording stopped")
        completion(tempURL)
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer,
                                     converter: AVAudioConverter,
                                     outputFormat: AVAudioFormat) {
        // Calculate output buffer size based on sample rate ratio
        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputFrameCount
        ) else { return }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, error == nil else {
            print("Conversion error: \(error?.localizedDescription ?? "unknown")")
            return
        }

        // Write to file
        do {
            try audioFile?.write(from: outputBuffer)
        } catch {
            print("Failed to write audio: \(error)")
        }

        // Calculate RMS from converted 16kHz buffer (consistent for VAD and visualization)
        var rms: Float = 0
        if let channelData = outputBuffer.floatChannelData?[0] {
            let frameLength = Int(outputBuffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
                sampleBuffer.append(sample)  // Accumulate for speech segments
            }
            rms = sqrt(sum / Float(frameLength))

            // Apply smoothing for stable visualization
            smoothedRMS = smoothedRMS * (1 - smoothingFactor) + rms * smoothingFactor

            // Convert to 0-1 range with amplification for visualization
            let level = min(1.0, smoothedRMS * 5.0)
            DispatchQueue.main.async { [weak self] in
                self?.onAudioLevel?(level)
            }
        }

        // Speech/silence detection using raw RMS (not smoothed, for accurate timing)
        // Pass actual frame count for accurate silence sample tracking
        detectSpeechSegment(rms: rms, frameCount: Int(outputBuffer.frameLength))
    }

    private func detectSpeechSegment(rms: Float, frameCount: Int) {
        let now = Date()

        if rms > silenceThreshold {
            // Sound detected - reset silence tracking
            silenceStartTime = nil
            actualSilenceSamples = 0

            if !isSpeaking {
                // Speech started
                isSpeaking = true
                speechStartTime = now
                print("🎙 Speech started")
            }
        } else {
            // Silence detected - track actual silence samples using real frame count
            actualSilenceSamples += frameCount

            if isSpeaking {
                if silenceStartTime == nil {
                    silenceStartTime = now
                }

                // Calculate current segment duration from buffer size
                let currentSegmentDuration = Double(sampleBuffer.count) / sampleRate

                // Force flush if segment exceeds maxSegmentDuration (even with short silence)
                // This prevents long segments that cause ASR to lose accuracy
                let shouldForceFlush = currentSegmentDuration >= maxSegmentDuration

                // Normal flush: silence >= silenceDuration
                // Force flush: segment >= maxSegmentDuration (at first silence moment)
                let silenceExceeded = silenceStartTime.map { now.timeIntervalSince($0) >= silenceDuration } ?? false

                if silenceExceeded || shouldForceFlush {
                    // Check minimum speech duration
                    if let speechStart = speechStartTime,
                       now.timeIntervalSince(speechStart) >= minSpeechDuration + (shouldForceFlush ? 0 : silenceDuration) {

                        // Remove actual tracked silence from buffer (not fixed 1.2s)
                        let segmentEnd = max(0, sampleBuffer.count - actualSilenceSamples)

                        if segmentEnd > Int(sampleRate * minSpeechDuration) {
                            // Use prefix/dropFirst for safe slicing
                            let segment = Array(sampleBuffer.prefix(segmentEnd))
                            let flushReason = shouldForceFlush ? "maxDuration" : "silence"
                            print("📝 Speech segment (\(flushReason)): \(segment.count) samples (\(Double(segment.count) / sampleRate)s)")

                            // Keep some overlap for context, but start fresh for next segment
                            sampleBuffer = Array(sampleBuffer.dropFirst(segmentEnd))

                            DispatchQueue.main.async { [weak self] in
                                self?.onSpeechSegment?(segment)
                            }
                        }
                    }

                    // Reset for next segment
                    isSpeaking = false
                    speechStartTime = nil
                    silenceStartTime = nil
                    actualSilenceSamples = 0
                }
            }
        }
    }
}
