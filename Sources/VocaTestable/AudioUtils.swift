import Foundation

/// Generate a sine wave for testing
public func generateSineWave(
    frequency: Float,
    duration: Double,
    sampleRate: Int = 16000,
    amplitude: Float = 0.5
) -> [Float] {
    let sampleCount = Int(duration * Double(sampleRate))
    return (0..<sampleCount).map { i in
        amplitude * sin(2.0 * Float.pi * frequency * Float(i) / Float(sampleRate))
    }
}

/// Generate silence
public func generateSilence(duration: Double, sampleRate: Int = 16000) -> [Float] {
    let sampleCount = Int(duration * Double(sampleRate))
    return [Float](repeating: 0, count: sampleCount)
}

/// Generate noise
public func generateNoise(duration: Double, sampleRate: Int = 16000, amplitude: Float = 0.001) -> [Float] {
    let sampleCount = Int(duration * Double(sampleRate))
    return (0..<sampleCount).map { _ in Float.random(in: -amplitude...amplitude) }
}

/// Concatenate multiple audio segments
public func concatenateAudio(_ segments: [[Float]]) -> [Float] {
    segments.flatMap { $0 }
}
