import Foundation
import AVFoundation

struct HistoryItem {
    let text: String
    let audioURL: URL?
    let timestamp: Date
}

class HistoryManager: NSObject, AVAudioPlayerDelegate {
    static let shared = HistoryManager()

    private var history: [HistoryItem] = []
    private var currentIndex: Int = -1
    private let maxItems = 10
    private var audioPlayer: AVAudioPlayer?
    private var tempPlaybackURL: URL?

    // Directory for storing audio recordings
    private lazy var recordingsDir: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Voca/recordings")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func add(_ text: String, audioURL: URL? = nil) {
        var savedAudioURL: URL? = nil

        // Copy audio file to permanent storage if provided
        if let sourceURL = audioURL {
            let filename = "recording_\(Date().timeIntervalSince1970).wav"
            let destURL = recordingsDir.appendingPathComponent(filename)
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                savedAudioURL = destURL
                print("Saved recording to: \(destURL.path)")
            } catch {
                print("Failed to save recording: \(error)")
            }
        }

        let item = HistoryItem(text: text, audioURL: savedAudioURL, timestamp: Date())

        // Add to front, remove oldest if over limit
        history.insert(item, at: 0)
        if history.count > maxItems {
            // Delete old audio file before removing
            if let oldAudioURL = history.last?.audioURL {
                try? FileManager.default.removeItem(at: oldAudioURL)
            }
            history.removeLast()
        }
        // Reset index for cycling
        currentIndex = -1

        // Notify observers
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .historyDidUpdate, object: nil)
        }
    }

    func getNext() -> String? {
        guard !history.isEmpty else { return nil }

        currentIndex = (currentIndex + 1) % history.count
        return history[currentIndex].text
    }

    func getAll() -> [String] {
        return history.map { $0.text }
    }

    func getAllItems() -> [HistoryItem] {
        return history
    }

    func getItem(at index: Int) -> HistoryItem? {
        guard index >= 0 && index < history.count else { return nil }
        return history[index]
    }

    /// Play the audio recording for a history item
    func playAudio(at index: Int) {
        guard let item = getItem(at: index),
              let audioURL = item.audioURL else {
            print("No audio available for this item")
            return
        }

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Audio file not found: \(audioURL.path)")
            return
        }

        do {
            audioPlayer?.stop()
            cleanupTempPlayback()
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            print("Playing: \(audioURL.lastPathComponent)")
        } catch {
            print("Direct playback failed: \(error), trying conversion...")
            playWithConversion(audioURL)
        }
    }

    private func playWithConversion(_ url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            try audioFile.read(into: buffer)

            guard let int16Format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: format.sampleRate,
                channels: format.channelCount,
                interleaved: true
            ) else { return }

            guard let converter = AVAudioConverter(from: format, to: int16Format) else { return }
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: int16Format, frameCapacity: frameCount) else { return }

            var inputConsumed = false
            var error: NSError?
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                if inputConsumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                outStatus.pointee = .haveData
                inputConsumed = true
                return buffer
            }

            if let error = error {
                print("Conversion failed: \(error)")
                return
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("playback_\(UUID().uuidString).wav")
            let outputFile = try AVAudioFile(forWriting: tempURL, settings: int16Format.settings)
            try outputFile.write(from: outputBuffer)

            tempPlaybackURL = tempURL
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Fallback playback failed: \(error)")
        }
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        cleanupTempPlayback()
    }

    private func cleanupTempPlayback() {
        if let url = tempPlaybackURL {
            try? FileManager.default.removeItem(at: url)
            tempPlaybackURL = nil
        }
    }

    /// Stop any currently playing audio
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        cleanupTempPlayback()
    }

    func clear() {
        // Delete all audio files
        for item in history {
            if let audioURL = item.audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }
        history.removeAll()
        currentIndex = -1
    }
}
