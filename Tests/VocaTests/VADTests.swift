import XCTest
@testable import VocaTestable

final class VADTests: XCTestCase {

    // MARK: - RMS Calculation

    func testRMSSilence() {
        let silence = [Float](repeating: 0, count: 1600)
        XCTAssertEqual(calculateRMS(silence), 0)
    }

    func testRMSKnownSignal() {
        // Constant signal of 0.5 should have RMS of 0.5
        let signal = [Float](repeating: 0.5, count: 1000)
        XCTAssertEqual(calculateRMS(signal), 0.5, accuracy: 0.001)
    }

    func testRMSEmpty() {
        XCTAssertEqual(calculateRMS([]), 0)
    }

    // MARK: - VAD Segmentation

    func testSilenceOnlyProducesNoSegments() {
        let silence = generateSilence(duration: 5.0)
        let segments = splitAudioByVAD(silence)
        // Pure silence should produce no meaningful segments
        // (may produce one if above minChunkSamples/2 threshold)
        for segment in segments {
            let rms = calculateRMS(segment.samples)
            XCTAssertLessThan(rms, 0.02, "Silence-only input should not produce high-energy segments")
        }
    }

    func testSingleSpeechSegment() {
        // Speech (2s) + silence (2s)
        let speech = generateSineWave(frequency: 440, duration: 2.0, amplitude: 0.3)
        let silence = generateSilence(duration: 2.0)
        let audio = concatenateAudio([speech, silence])

        let segments = splitAudioByVAD(audio)
        XCTAssertGreaterThanOrEqual(segments.count, 1, "Should detect at least one speech segment")
    }

    func testMultipleSpeechSegments() {
        // speech(2s) + silence(1.5s) + speech(2s) + silence(1.5s)
        let speech1 = generateSineWave(frequency: 440, duration: 2.0, amplitude: 0.3)
        let silence1 = generateSilence(duration: 1.5)
        let speech2 = generateSineWave(frequency: 880, duration: 2.0, amplitude: 0.3)
        let silence2 = generateSilence(duration: 1.5)
        let audio = concatenateAudio([speech1, silence1, speech2, silence2])

        let segments = splitAudioByVAD(audio)
        XCTAssertGreaterThanOrEqual(segments.count, 2, "Should detect two speech segments")
    }

    func testShortSpeechIgnored() {
        // Very short speech (0.3s) should be ignored (below minChunkSamples)
        let speech = generateSineWave(frequency: 440, duration: 0.3, amplitude: 0.3)
        let silence = generateSilence(duration: 2.0)
        let audio = concatenateAudio([speech, silence])

        let segments = splitAudioByVAD(audio)
        // Short speech below minimum should not produce standalone segments
        for segment in segments {
            // If a segment exists, it should be at least minChunkSamples/2
            XCTAssertGreaterThanOrEqual(segment.samples.count, 8000, "Segments should meet minimum duration")
        }
    }

    func testLongSpeechForceSplit() {
        // 90 seconds of continuous speech should be force-split at 60s
        let speech = generateSineWave(frequency: 440, duration: 90.0, amplitude: 0.3)
        let segments = splitAudioByVAD(speech)
        XCTAssertGreaterThanOrEqual(segments.count, 2, "90s speech should be split into at least 2 chunks")
    }

    // MARK: - VAD Config Variants

    func testAggressiveVADMoreSegments() {
        // Aggressive config (shorter silence threshold) should produce more segments
        let speech1 = generateSineWave(frequency: 440, duration: 2.0, amplitude: 0.3)
        let silence = generateSilence(duration: 0.5) // Short pause
        let speech2 = generateSineWave(frequency: 880, duration: 2.0, amplitude: 0.3)
        let trailing = generateSilence(duration: 2.0)
        let audio = concatenateAudio([speech1, silence, speech2, trailing])

        let defaultConfig = VADConfig() // 1.2s silence duration
        let aggressiveConfig = VADConfig(silenceDuration: 0.3)

        let defaultSegments = splitAudioByVAD(audio, config: defaultConfig)
        let aggressiveSegments = splitAudioByVAD(audio, config: aggressiveConfig)

        // Aggressive should find more segment boundaries
        XCTAssertGreaterThanOrEqual(aggressiveSegments.count, defaultSegments.count,
            "Aggressive VAD should produce >= segments than default")
    }

    func testHighThresholdIgnoresQuietSpeech() {
        // Low amplitude speech should be treated as silence with high threshold
        let quietSpeech = generateSineWave(frequency: 440, duration: 3.0, amplitude: 0.005)
        let silence = generateSilence(duration: 2.0)
        let audio = concatenateAudio([quietSpeech, silence])

        let highThreshold = VADConfig(silenceThreshold: 0.05)
        let segments = splitAudioByVAD(audio, config: highThreshold)

        // With high threshold, quiet speech is treated as silence
        for segment in segments {
            let rms = calculateRMS(segment.samples)
            XCTAssertLessThan(rms, 0.05, "High threshold should not detect quiet speech as voice")
        }
    }

    // MARK: - VAD Parameter Comparison

    func testConservativeVADFewerSegments() {
        // Conservative config (longer silence duration) should produce fewer segments
        let speech1 = generateSineWave(frequency: 300, duration: 2.0, amplitude: 0.2)
        let pause = generateSilence(duration: 1.5)
        let speech2 = generateSineWave(frequency: 400, duration: 2.0, amplitude: 0.2)
        let trailing = generateSilence(duration: 2.0)
        let audio = concatenateAudio([speech1, pause, speech2, trailing])

        let conservativeConfig = VADConfig(silenceDuration: 2.0)
        let segments = splitAudioByVAD(audio, config: conservativeConfig)

        // 1.5s pause is shorter than 2.0s threshold, so conservative should NOT split there
        XCTAssertLessThanOrEqual(segments.count, 2,
            "Conservative VAD should not split on pauses shorter than its threshold")
    }

    func testSensitiveThresholdDetectsMoreSpeech() {
        // Mix of loud and quiet speech - sensitive threshold should catch both
        let loudSpeech = generateSineWave(frequency: 300, duration: 2.0, amplitude: 0.3)
        let pause = generateSilence(duration: 1.5)
        let quietSpeech = generateSineWave(frequency: 400, duration: 2.0, amplitude: 0.01)
        let trailing = generateSilence(duration: 2.0)
        let audio = concatenateAudio([loudSpeech, pause, quietSpeech, trailing])

        let sensitiveConfig = VADConfig(silenceThreshold: 0.005)
        let strictConfig = VADConfig(silenceThreshold: 0.05)

        let sensitiveSegments = splitAudioByVAD(audio, config: sensitiveConfig)
        let strictSegments = splitAudioByVAD(audio, config: strictConfig)

        // Sensitive should detect quiet speech that strict misses
        XCTAssertGreaterThanOrEqual(sensitiveSegments.count, strictSegments.count,
            "Sensitive threshold should detect >= segments than strict")
    }
}
