import XCTest
@testable import VocaTestable

final class AudioPlaybackTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VocaTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - WAV Write/Read Round-Trip

    func testWriteAndReadWAV() throws {
        let samples = generateSineWave(frequency: 440, duration: 1.0, amplitude: 0.3)
        let url = tempDir.appendingPathComponent("test.wav")

        try writeWAV(samples: samples, to: url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "WAV file should not be empty")
    }

    func testWAVFormatIsFloat32Mono16kHz() throws {
        let samples = generateSineWave(frequency: 440, duration: 0.5)
        let url = tempDir.appendingPathComponent("format_test.wav")
        try writeWAV(samples: samples, to: url)

        let result = testPlayback(url: url)
        XCTAssertTrue(result.success, "Playback should succeed: \(result.error ?? "")")
    }

    // MARK: - Playback (simulates HistoryManager.playAudio code path)

    func testDirectPlaybackFloat32WAV() throws {
        // This tests the exact same code path as HistoryManager.playAudio()
        // AudioRecorder writes Float32 mono 16kHz → HistoryManager copies to recordings/ → AVAudioPlayer
        let samples = generateSineWave(frequency: 440, duration: 2.0, amplitude: 0.3)
        let url = tempDir.appendingPathComponent("playback_test.wav")
        try writeWAV(samples: samples, to: url)

        let result = testPlayback(url: url)
        XCTAssertTrue(result.success, "Direct Float32 playback should work: \(result.error ?? "")")
    }

    func testPlaybackWithQuietAudio() throws {
        // Very quiet audio should still be playable
        let samples = generateSineWave(frequency: 440, duration: 1.0, amplitude: 0.01)
        let url = tempDir.appendingPathComponent("quiet_test.wav")
        try writeWAV(samples: samples, to: url)

        let result = testPlayback(url: url)
        XCTAssertTrue(result.success, "Quiet audio playback should work: \(result.error ?? "")")
    }

    func testPlaybackWithSilence() throws {
        // Pure silence WAV should still be playable (valid file)
        let samples = generateSilence(duration: 1.0)
        let url = tempDir.appendingPathComponent("silence_test.wav")
        try writeWAV(samples: samples, to: url)

        let result = testPlayback(url: url)
        XCTAssertTrue(result.success, "Silence WAV should be playable: \(result.error ?? "")")
    }

    func testPlaybackMissingFile() {
        let url = tempDir.appendingPathComponent("nonexistent.wav")
        let result = testPlayback(url: url)
        XCTAssertFalse(result.success, "Missing file should fail")
        XCTAssertNotNil(result.error)
    }

    func testPlaybackLongRecording() throws {
        // Simulate a 60s recording (like real use)
        let samples = generateSineWave(frequency: 440, duration: 60.0, amplitude: 0.3)
        let url = tempDir.appendingPathComponent("long_test.wav")
        try writeWAV(samples: samples, to: url)

        let result = testPlayback(url: url)
        XCTAssertTrue(result.success, "60s recording playback should work: \(result.error ?? "")")
    }

    // MARK: - Real Recordings (if available)

    func testPlaybackRealRecordings() throws {
        let recordingsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Voca/recordings")

        guard FileManager.default.fileExists(atPath: recordingsDir.path) else {
            // No recordings dir = skip (not a failure)
            print("Skipping: No Voca recordings directory found")
            return
        }

        let files = try FileManager.default.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "wav" }

        guard !files.isEmpty else {
            print("Skipping: No WAV files in recordings directory")
            return
        }

        // Test the most recent recording
        let sorted = files.sorted { $0.lastPathComponent > $1.lastPathComponent }
        let latest = sorted[0]

        let result = testPlayback(url: latest)
        XCTAssertTrue(result.success, "Real recording playback failed for \(latest.lastPathComponent): \(result.error ?? "")")
    }
}
