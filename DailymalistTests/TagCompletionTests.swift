import Foundation
import Testing
@testable import Dailymalist

@MainActor
struct TagCompletionTests {
    @Test func startsWithHashAndFiltersProgressively() {
        #expect(TagCompletion.active(in: "Comprar #", selection: NSRange(location: 9, length: 0))?.query == "")
        #expect(TagCompletion.active(in: "Comprar #Tr", selection: NSRange(location: 11, length: 0))?.query == "Tr")
        #expect(TagCompletion.matches("Vídeos", query: "vi"))
        #expect(!TagCompletion.matches("Trabajo", query: "vi"))
    }
    @Test func respectsCaretAndWholeTokenWithEmoji() {
        let value = "🎉 #Trabajo mañana" as NSString
        let caret = ("🎉 #Tra" as NSString).length
        let active = TagCompletion.active(in: value as String, selection: NSRange(location: caret, length: 0))
        #expect(active?.query == "Tra")
        #expect(active.map { value.substring(with: $0.range) } == "#Trabajo")
        #expect(TagCompletion.active(in: "#Trabajo ", selection: NSRange(location: 9, length: 0)) == nil)
    }
    @Test func ignoresLinksAndSelections() {
        for value in ["https://example.com/#foo", "abc#foo", "##foo"] {
            #expect(TagCompletion.active(in: value, selection: NSRange(location: value.utf16.count, length: 0)) == nil)
        }
        #expect(TagCompletion.active(in: "#foo", selection: NSRange(location: 0, length: 4)) == nil)
    }
}
