import Foundation
import AVFoundation

struct HistoryItem {
    let text: String
    let audioURL: URL?
    let timestamp: Date
}

class HistoryManager {
    private var history: [HistoryItem] = []
    private var currentIndex: Int = -1
    private let maxItems = 10  // Increased for debugging
    private var audioPlayer: AVAudioPlayer?

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

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            print("Playing: \(audioURL.lastPathComponent)")
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    /// Stop any currently playing audio
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
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
