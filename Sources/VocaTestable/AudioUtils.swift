import AVFoundation
import Foundation

/// Write Float32 samples to a WAV file (matches AudioRecorder output format)
public func writeWAV(samples: [Float], sampleRate: Int = 16000, to url: URL) throws {
    guard let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Double(sampleRate),
        channels: 1,
        interleaved: false
    ) else { throw NSError(domain: "AudioUtils", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create format"]) }

    let file = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
        throw NSError(domain: "AudioUtils", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create buffer"])
    }
    buffer.frameLength = AVAudioFrameCount(samples.count)
    samples.withUnsafeBufferPointer { ptr in
        buffer.floatChannelData![0].update(from: ptr.baseAddress!, count: samples.count)
    }
    try file.write(from: buffer)
}

/// Test playback of a WAV file. Returns (success, errorMessage).
public func testPlayback(url: URL) -> (success: Bool, error: String?) {
    guard FileManager.default.fileExists(atPath: url.path) else {
        return (false, "File not found: \(url.path)")
    }
    // Verify readable as audio
    do {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frames = audioFile.length
        guard frames > 0 else { return (false, "Empty audio file") }

        // Test AVAudioPlayer creation (same code path as HistoryManager.playAudio)
        let player = try AVAudioPlayer(contentsOf: url)
        guard player.duration > 0 else { return (false, "Player reports 0 duration") }

        return (true, nil)
    } catch {
        // Try Float32→Int16 conversion fallback (same as HistoryManager.playWithConversion)
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return (false, "Cannot create read buffer")
            }
            try audioFile.read(into: buffer)

            guard let int16Format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: format.sampleRate, channels: format.channelCount, interleaved: true),
                  let converter = AVAudioConverter(from: format, to: int16Format),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: int16Format, frameCapacity: frameCount) else {
                return (false, "Cannot create converter for fallback")
            }

            var convError: NSError?
            converter.convert(to: outputBuffer, error: &convError) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if let convError = convError { return (false, "Conversion failed: \(convError)") }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).wav")
            let outputFile = try AVAudioFile(forWriting: tempURL, settings: int16Format.settings)
            try outputFile.write(from: outputBuffer)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            let player = try AVAudioPlayer(contentsOf: tempURL)
            guard player.duration > 0 else { return (false, "Converted player reports 0 duration") }

            return (true, nil)
        } catch {
            return (false, "Both direct and fallback failed: \(error)")
        }
    }
}

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
