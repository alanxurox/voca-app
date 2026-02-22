import Foundation

/// Post-process transcribed text: filler removal and formatting.
/// Extracted from AppDelegate.postProcessText in VoiceTranslatorApp.swift.
public func postProcessText(_ text: String) -> String {
    var result = text

    // 1. Remove basic filler words (multiple languages)
    // English: um, uh, er, ah, hmm
    // Chinese: 呃, 嗯, 啊, 那个
    // Japanese: えーと, あの, えー
    // Korean: 음, 어
    let fillerWords = ["um", "uh", "er", "ah", "hmm", "呃", "嗯", "啊", "那个", "えーと", "あの", "えー", "음", "어"]
    for filler in fillerWords {
        // Remove filler surrounded by spaces
        result = result.replacingOccurrences(of: " \(filler) ", with: " ", options: .caseInsensitive)
        // Remove filler at start
        result = result.replacingOccurrences(of: "^\(filler) ", with: "", options: [.caseInsensitive, .regularExpression])
        // Remove filler followed by comma
        result = result.replacingOccurrences(of: " \(filler),", with: ",", options: .caseInsensitive)
    }

    // 2. Fix spacing and punctuation
    result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)  // Multiple spaces
    result = result.replacingOccurrences(of: " ,", with: ",")  // Space before comma
    result = result.replacingOccurrences(of: " \\.", with: ".", options: .regularExpression)  // Space before period

    // 3. Clean up duplicate/mixed punctuation
    // Detect if text is primarily Chinese (contains CJK characters)
    let isChinese = result.range(of: "\\p{Han}", options: .regularExpression) != nil

    if isChinese {
        // Chinese text: normalize to Chinese punctuation
        result = result.replacingOccurrences(of: "[。.\\s]*[。.][。.\\s]*", with: "。", options: .regularExpression)
        result = result.replacingOccurrences(of: "[，,\\s]*[，,][，,\\s]*", with: "，", options: .regularExpression)
        result = result.replacingOccurrences(of: "[？?\\s]*[？?][？?\\s]*", with: "？", options: .regularExpression)
        result = result.replacingOccurrences(of: "[！!\\s]*[！!][！!\\s]*", with: "！", options: .regularExpression)
        // Remove comma before period: ，。 → 。
        result = result.replacingOccurrences(of: "，。", with: "。")
        result = result.replacingOccurrences(of: "。，", with: "。")
        // Remove period after question/exclamation
        result = result.replacingOccurrences(of: "？[。.]", with: "？", options: .regularExpression)
        result = result.replacingOccurrences(of: "！[。.]", with: "！", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\?[。.]", with: "？", options: .regularExpression)
        result = result.replacingOccurrences(of: "![。.]", with: "！", options: .regularExpression)
    } else {
        // English text: normalize to English punctuation
        result = result.replacingOccurrences(of: "[.\\s]*\\.[.\\s]*", with: ". ", options: .regularExpression)
        result = result.replacingOccurrences(of: ",+", with: ",", options: .regularExpression)
        result = result.replacingOccurrences(of: ",\\s*\\.", with: ".", options: .regularExpression)  // Comma before period → period
        result = result.replacingOccurrences(of: "\\.\\s*,", with: ",", options: .regularExpression)  // Period before comma → comma
        result = result.replacingOccurrences(of: "\\?+", with: "?", options: .regularExpression)
        result = result.replacingOccurrences(of: "!+", with: "!", options: .regularExpression)
    }

    // Clean up any remaining multiple spaces
    result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)

    // 4. Capitalize first letter (for English text)
    if let first = result.first {
        result = first.uppercased() + result.dropFirst()
    }

    return result.trimmingCharacters(in: .whitespaces)
}
