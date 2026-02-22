import XCTest
@testable import VocaTestable

final class TextPostProcessingTests: XCTestCase {

    func testFillerWordRemoval() {
        // Test common filler words are removed
        let input = "uh so um I think uhh this is uh working"
        let result = postProcessText(input)
        XCTAssertFalse(result.contains(" uh "), "Should remove 'uh'")
        XCTAssertFalse(result.contains(" um "), "Should remove 'um'")
        XCTAssertTrue(result.contains("think"), "Should keep real words")
        XCTAssertTrue(result.contains("working"), "Should keep real words")
    }

    func testEmptyInput() {
        XCTAssertEqual(postProcessText(""), "")
    }

    func testWhitespaceNormalization() {
        let input = "hello   world"
        let result = postProcessText(input)
        XCTAssertFalse(result.contains("  "), "Should normalize double spaces")
    }

    func testCJKPunctuation() {
        // Chinese text with mixed punctuation should be normalized
        let input = "你好 , 世界"
        let result = postProcessText(input)
        // CJK text should not have spaces before/after punctuation
        XCTAssertFalse(result.contains(" ,") || result.contains(", ") && result.contains("你"),
            "CJK punctuation should be cleaned up")
    }

    func testPreservesNormalText() {
        let input = "This is a normal sentence."
        let result = postProcessText(input)
        XCTAssertEqual(result.trimmed, input.trimmed, "Normal text should be preserved")
    }

    func testFillerAtStart() {
        // "uh" at the start of a sentence should be removed
        let input = "uh this is a test"
        let result = postProcessText(input)
        XCTAssertFalse(result.lowercased().hasPrefix("uh "), "Should remove leading filler word")
        XCTAssertTrue(result.contains("test"), "Should keep real content")
    }

    func testMultipleFillerWords() {
        let input = "um so uh I um think er this is ah good"
        let result = postProcessText(input)
        XCTAssertFalse(result.contains(" um "), "Should remove 'um'")
        XCTAssertFalse(result.contains(" uh "), "Should remove 'uh'")
        XCTAssertFalse(result.contains(" er "), "Should remove 'er'")
        XCTAssertFalse(result.contains(" ah "), "Should remove 'ah'")
        XCTAssertTrue(result.contains("think"), "Should keep real words")
        XCTAssertTrue(result.contains("good"), "Should keep real words")
    }

    func testCapitalization() {
        // First letter should be capitalized
        let input = "hello world"
        let result = postProcessText(input)
        XCTAssertTrue(result.first?.isUppercase ?? false, "First letter should be capitalized")
    }

    func testSpaceBeforeComma() {
        let input = "hello , world"
        let result = postProcessText(input)
        XCTAssertFalse(result.contains(" ,"), "Should remove space before comma")
    }

    func testChinesePunctuationNormalization() {
        // Duplicate Chinese period should collapse to one
        let input = "你好。。世界"
        let result = postProcessText(input)
        XCTAssertFalse(result.contains("。。"), "Duplicate Chinese periods should be normalized")
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
