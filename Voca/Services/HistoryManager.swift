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
        var savedAudioURL: URL?

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

        history.insert(item, at: 0)
        if history.count > maxItems {
            if let oldAudioURL = history.last?.audioURL {
                try? FileManager.default.removeItem(at: oldAudioURL)
            }
            history.removeLast()
        }
        currentIndex = -1

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .historyDidUpdate, object: nil)
        }
    }

    func nextItem() -> String? {
        guard !history.isEmpty else { return nil }

        currentIndex = (currentIndex + 1) % history.count
        return history[currentIndex].text
    }

    var allItems: [HistoryItem] { history }

    func item(at index: Int) -> HistoryItem? {
        guard index >= 0 && index < history.count else { return nil }
        return history[index]
    }

    /// Play the audio recording for a history item by index
    func playAudio(at index: Int) {
        guard let item = item(at: index),
              let audioURL = item.audioURL else {
            print("playAudio(at:): no audio for index \(index)")
            return
        }
        playAudio(url: audioURL)
    }

    /// Play audio directly from a URL (preferred — avoids stale index issues)
    func playAudio(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("playAudio(url:): file not found: \(url.path)")
            return
        }

        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        cleanupTempPlayback()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Direct playback failed: \(error), trying conversion...")
            playWithConversion(url)
        }
    }

    private func playWithConversion(_ url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("playWithConversion: failed to create input buffer")
                return
            }
            try audioFile.read(into: buffer)

            guard let int16Format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: format.sampleRate,
                channels: format.channelCount,
                interleaved: true
            ) else {
                print("playWithConversion: failed to create int16 format")
                return
            }

            guard let converter = AVAudioConverter(from: format, to: int16Format) else {
                print("playWithConversion: failed to create converter")
                return
            }
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: int16Format, frameCapacity: frameCount) else {
                print("playWithConversion: failed to create output buffer")
                return
            }

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
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil
        cleanupTempPlayback()
    }

    func clear() {
        stopAudio()
        for item in history {
            if let audioURL = item.audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }
        history.removeAll()
        currentIndex = -1
    }
}
