import Foundation
import AVFoundation
import VoicePipeline

struct TranscriptionResult {
    let text: String?
    let modelTime: TimeInterval
}

class Transcriber {
    private let engine: ASREngine

    init(engine: ASREngine) {
        self.engine = engine
    }

    func transcribe(audioURL: URL, completion: @escaping (TranscriptionResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(TranscriptionResult(text: nil, modelTime: 0))
                return
            }

            let result = self.runTranscription(audioURL: audioURL)
            completion(result)
        }
    }

    private func runTranscription(audioURL: URL) -> TranscriptionResult {
        // Load audio file to float array
        guard let audioSamples = loadAudioFile(url: audioURL) else {
            return TranscriptionResult(text: nil, modelTime: 0)
        }

        let modelStart = Date()

        // For short audio (< 60 seconds), transcribe directly
        let sampleRate = 16000
        let maxChunkSamples = 60 * sampleRate  // 60 seconds max per chunk

        if audioSamples.count <= maxChunkSamples {
            let text = transcribeChunk(audioSamples)
            let modelTime = Date().timeIntervalSince(modelStart)
            return TranscriptionResult(text: text, modelTime: modelTime)
        }

        // For longer audio, use VAD-based chunking
        let chunks = splitAudioByVAD(audioSamples, sampleRate: sampleRate, maxChunkSamples: maxChunkSamples)

        var results: [String] = []
        for chunk in chunks {
            if let text = transcribeChunk(chunk), !text.isEmpty {
                results.append(text)
            }
        }

        let modelTime = Date().timeIntervalSince(modelStart)
        let combinedText = results.joined(separator: " ")

        return TranscriptionResult(text: combinedText.isEmpty ? nil : combinedText, modelTime: modelTime)
    }

    private func transcribeChunk(_ samples: [Float]) -> String? {
        let kotlinArray = KotlinFloatArray(size: Int32(samples.count))
        for (index, sample) in samples.enumerated() {
            kotlinArray.set(index: Int32(index), value: sample)
        }
        return engine.transcribe(audio: kotlinArray)
    }

    /// Split audio into chunks using energy-based VAD (Voice Activity Detection)
    private func splitAudioByVAD(_ samples: [Float], sampleRate: Int, maxChunkSamples: Int) -> [[Float]] {
        let minSilenceSamples = Int(0.3 * Double(sampleRate))  // 300ms minimum silence
        let minChunkSamples = sampleRate  // 1 second minimum chunk
        let windowSize = Int(0.025 * Double(sampleRate))  // 25ms window for energy calculation
        let energyThreshold: Float = 0.01  // Silence threshold

        var chunks: [[Float]] = []
        var currentChunkStart = 0
        var silenceStart: Int? = nil

        var i = 0
        while i < samples.count {
            // Calculate energy for this window
            let windowEnd = min(i + windowSize, samples.count)
            var energy: Float = 0
            for j in i..<windowEnd {
                energy += samples[j] * samples[j]
            }
            energy /= Float(windowEnd - i)

            let isSilence = energy < energyThreshold

            if isSilence {
                if silenceStart == nil {
                    silenceStart = i
                }
            } else {
                if let start = silenceStart {
                    let silenceLength = i - start
                    let chunkLength = i - currentChunkStart

                    // If we have enough silence and a reasonable chunk, split here
                    if silenceLength >= minSilenceSamples && chunkLength >= minChunkSamples {
                        let splitPoint = start + silenceLength / 2  // Split in middle of silence
                        let chunk = Array(samples[currentChunkStart..<splitPoint])
                        chunks.append(chunk)
                        currentChunkStart = splitPoint
                    }
                }
                silenceStart = nil
            }

            // Force split if chunk is too long (for continuous speech)
            let chunkLength = i - currentChunkStart
            if chunkLength >= maxChunkSamples {
                // Try to find a recent silence point, or just split
                let chunk = Array(samples[currentChunkStart..<i])
                chunks.append(chunk)
                currentChunkStart = i
                silenceStart = nil
            }

            i += windowSize
        }

        // Add remaining samples as final chunk
        if currentChunkStart < samples.count {
            let chunk = Array(samples[currentChunkStart...])
            if chunk.count >= minChunkSamples / 2 {  // Only add if meaningful
                chunks.append(chunk)
            }
        }

        print("📊 Split audio into \(chunks.count) chunks")
        return chunks
    }

    /// Load WAV/M4A audio file and convert to 16kHz mono float samples
    private func loadAudioFile(url: URL) -> [Float]? {
        do {
            let audioFile = try AVAudioFile(forReading: url)

            // Target format: 16kHz, mono, float
            guard let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16000,
                channels: 1,
                interleaved: false
            ) else {
                print("Failed to create target audio format")
                return nil
            }

            // Create converter
            guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: targetFormat) else {
                print("Failed to create audio converter")
                return nil
            }

            // Calculate output buffer size
            let inputLength = AVAudioFrameCount(audioFile.length)
            let ratio = targetFormat.sampleRate / audioFile.processingFormat.sampleRate
            let outputLength = AVAudioFrameCount(Double(inputLength) * ratio)

            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputLength) else {
                print("Failed to create output buffer")
                return nil
            }

            // Read input
            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: inputLength
            ) else {
                print("Failed to create input buffer")
                return nil
            }

            try audioFile.read(into: inputBuffer)

            // Convert
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }

            converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                print("Audio conversion error: \(error)")
                return nil
            }

            // Extract float samples
            guard let floatData = outputBuffer.floatChannelData?[0] else {
                print("Failed to get float channel data")
                return nil
            }

            let frameCount = Int(outputBuffer.frameLength)
            var samples = [Float](repeating: 0, count: frameCount)
            for i in 0..<frameCount {
                samples[i] = floatData[i]
            }

            return samples

        } catch {
            print("Error loading audio file: \(error)")
            return nil
        }
    }

    // Legacy methods for compatibility (no-op since model is fixed in ASREngine)
    func setModel(_ model: ASRModel) {
        // Model selection handled by ASREngine internally
        // For now, only SenseVoice is supported
    }
}
