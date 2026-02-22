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
    private let silenceDuration: Double = 1.2   // Seconds of silence to trigger segment end (longer to avoid breaking natural pauses)
    private let minSpeechDuration: Double = 1.0 // Minimum speech duration to process

    // Speech segment tracking
    private var sampleBuffer: [Float] = []
    private var silenceStartTime: Date?
    private var speechStartTime: Date?
    private var isSpeaking = false

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

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isRecording = false

        // Flush any remaining speech in buffer (user explicitly stopped, so use a lower
        // threshold than live VAD — don't drop short final phrases like "thank you")
        let minFlushSamples = Int(sampleRate * 0.15)  // 150ms minimum for final flush
        if sampleBuffer.count > minFlushSamples {
            let segment = sampleBuffer
            sampleBuffer = []
            print("📝 Flushing final segment: \(segment.count) samples")
            onSpeechSegment?(segment)
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
        detectSpeechSegment(rms: rms)
    }

    private func detectSpeechSegment(rms: Float) {
        let now = Date()

        if rms > silenceThreshold {
            // Sound detected
            silenceStartTime = nil

            if !isSpeaking {
                // Speech started
                isSpeaking = true
                speechStartTime = now
                print("🎤 Speech started")
            }
        } else {
            // Silence detected
            if isSpeaking {
                if silenceStartTime == nil {
                    silenceStartTime = now
                } else if let silenceStart = silenceStartTime,
                          now.timeIntervalSince(silenceStart) >= silenceDuration {
                    // Silence duration exceeded - segment complete

                    // Check minimum speech duration
                    if let speechStart = speechStartTime,
                       now.timeIntervalSince(speechStart) >= minSpeechDuration + silenceDuration {

                        // Remove trailing silence from buffer (approximate)
                        let silenceSamples = Int(silenceDuration * sampleRate)
                        let segmentEnd = max(0, sampleBuffer.count - silenceSamples)

                        if segmentEnd > Int(sampleRate * minSpeechDuration) {
                            let segment = Array(sampleBuffer[0..<segmentEnd])
                            print("📝 Speech segment: \(segment.count) samples (\(Double(segment.count) / sampleRate)s)")

                            // Keep some overlap for context, but start fresh for next segment
                            sampleBuffer = Array(sampleBuffer[segmentEnd...])

                            DispatchQueue.main.async { [weak self] in
                                self?.onSpeechSegment?(segment)
                            }
                        }
                    }

                    // Reset for next segment
                    isSpeaking = false
                    speechStartTime = nil
                    silenceStartTime = nil
                }
            }
        }
    }
}
