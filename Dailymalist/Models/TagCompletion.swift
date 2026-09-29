import Foundation

/// UTF-16 ranges match UITextView selections, including text containing emoji.
enum TagCompletion {
    static func active(in text: String, selection: NSRange) -> (query: String, range: NSRange)? {
        let source = text as NSString
        guard selection.length == 0, selection.location <= source.length else { return nil }
        let prefix = source.substring(to: selection.location)
        let regex = try! NSRegularExpression(pattern: #"(?<![\p{L}\p{M}\p{N}_/#])#([\p{L}\p{M}\p{N}_]*)$"#)
        guard let match = regex.firstMatch(in: prefix, range: NSRange(location: 0, length: (prefix as NSString).length)) else { return nil }
        let suffix = source.substring(from: selection.location) as NSString
        let tail = suffix.range(of: #"^[\p{L}\p{M}\p{N}_]*"#, options: .regularExpression)
        return ((prefix as NSString).substring(with: match.range(at: 1)),
                NSRange(location: match.range.location, length: match.range.length + tail.length))
    }

    static func matches(_ name: String, query: String) -> Bool {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES"))
            .hasPrefix(query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES")))
    }
}
