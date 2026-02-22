import Foundation

/// VAD configuration parameters
public struct VADConfig {
    public let silenceThreshold: Float    // RMS threshold for silence
    public let silenceDuration: Double     // Seconds of silence to trigger segment end
    public let minSpeechDuration: Double   // Minimum speech duration to process
    public let sampleRate: Int

    public init(
        silenceThreshold: Float = 0.02,
        silenceDuration: Double = 1.2,
        minSpeechDuration: Double = 1.0,
        sampleRate: Int = 16000
    ) {
        self.silenceThreshold = silenceThreshold
        self.silenceDuration = silenceDuration
        self.minSpeechDuration = minSpeechDuration
        self.sampleRate = sampleRate
    }
}

/// Result of VAD segmentation
public struct VADSegment {
    public let samples: [Float]
    public let startSample: Int
    public let endSample: Int

    public var duration: Double {
        Double(samples.count) / 16000.0
    }
}

/// Calculate RMS energy of a sample buffer
public func calculateRMS(_ samples: [Float]) -> Float {
    guard !samples.isEmpty else { return 0 }
    let sumSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
    return sqrt(sumSquares / Float(samples.count))
}

/// Split audio into speech segments using energy-based VAD
/// This is the testable version of Transcriber.splitAudioByVAD
public func splitAudioByVAD(
    _ samples: [Float],
    config: VADConfig = VADConfig(),
    maxChunkSeconds: Int = 60
) -> [VADSegment] {
    let sampleRate = config.sampleRate
    let maxChunkSamples = maxChunkSeconds * sampleRate
    let minSilenceSamples = Int(0.3 * Double(sampleRate))
    let minChunkSamples = sampleRate  // 1 second minimum
    let windowSize = Int(0.025 * Double(sampleRate))  // 25ms
    let energyThreshold = config.silenceThreshold

    var segments: [VADSegment] = []
    var currentChunkStart = 0
    var silenceStart: Int? = nil

    var i = 0
    while i < samples.count {
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

                if silenceLength >= minSilenceSamples && chunkLength >= minChunkSamples {
                    let splitPoint = start + silenceLength / 2
                    let chunk = Array(samples[currentChunkStart..<splitPoint])
                    segments.append(VADSegment(
                        samples: chunk,
                        startSample: currentChunkStart,
                        endSample: splitPoint
                    ))
                    currentChunkStart = splitPoint
                }
            }
            silenceStart = nil
        }

        let chunkLength = i - currentChunkStart
        if chunkLength >= maxChunkSamples {
            let chunk = Array(samples[currentChunkStart..<i])
            segments.append(VADSegment(
                samples: chunk,
                startSample: currentChunkStart,
                endSample: i
            ))
            currentChunkStart = i
            silenceStart = nil
        }

        i += windowSize
    }

    if currentChunkStart < samples.count {
        let chunk = Array(samples[currentChunkStart...])
        if chunk.count >= minChunkSamples / 2 {
            segments.append(VADSegment(
                samples: chunk,
                startSample: currentChunkStart,
                endSample: samples.count
            ))
        }
    }

    return segments
}
