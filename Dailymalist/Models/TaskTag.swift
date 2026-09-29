import Foundation
import SwiftData
import SwiftUI

@Model
final class TaskTag {
    @Attribute(.unique) var id: UUID
    var name: String
    // Components are portable, persistent values; SwiftUI.Color is not stored.
    var red: Double
    var green: Double
    var blue: Double
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.tags)
    var tasks: [TaskItem]? = []

    init(name: String, color: Color = .cyan) {
        id = UUID()
        self.name = name
        let components = color.resolve(in: EnvironmentValues())
        red = Double(components.red)
        green = Double(components.green)
        blue = Double(components.blue)
    }

    var color: Color {
        get { Color(red: red, green: green, blue: blue) }
        set {
            let components = newValue.resolve(in: EnvironmentValues())
            red = Double(components.red)
            green = Double(components.green)
            blue = Double(components.blue)
        }
    }
}

enum TagSyntax {
    static func key(_ name: String) -> String {
        name.precomposedStringWithCanonicalMapping.lowercased()
    }

    static func validName(_ name: String) -> Bool {
        !name.isEmpty && name.range(of: #"^[\p{L}\p{M}\p{N}_]+$"#, options: .regularExpression) != nil
    }

    static func mentions(in text: String) -> [(name: String, range: NSRange)] {
        let expression = try! NSRegularExpression(pattern: #"(?<![\p{L}\p{M}\p{N}_/#])#([\p{L}\p{M}\p{N}_]+)"#)
        let source = text as NSString
        return expression.matches(in: text, range: NSRange(location: 0, length: source.length)).map {
            (source.substring(with: $0.range(at: 1)), $0.range)
        }
    }

    static func extract(from text: inout String, tags: inout [TaskTag], available: [TaskTag]) -> [String] {
        let matches = mentions(in: text)
        var unknown: [String] = []
        for match in matches {
            if let tag = available.first(where: { key($0.name) == key(match.name) }) {
                if !tags.contains(where: { $0.id == tag.id }) { tags.append(tag) }
            } else if !unknown.contains(where: { key($0) == key(match.name) }) {
                unknown.append(match.name)
            }
        }
        let result = NSMutableString(string: text)
        for match in matches.reversed() where available.contains(where: { key($0.name) == key(match.name) }) {
            result.deleteCharacters(in: match.range)
        }
        text = (result as String).replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return unknown
    }
}
