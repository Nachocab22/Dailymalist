import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import Dailymalist

@MainActor
struct TaskTagTests {
    @Test func extractsTagsAnywhereWithoutDuplicates() {
        let work = TaskTag(name: "Trabajo")
        let video = TaskTag(name: "Vídeo")
        var text = "#Trabajo Preparar #Vídeo guion #TRABAJO"
        var tags: [TaskTag] = []
        let unknown = TagSyntax.extract(from: &text, tags: &tags, available: [work, video])
        #expect(text == "Preparar guion")
        #expect(tags.map(\.id) == [work.id, video.id])
        #expect(unknown.isEmpty)
    }

    @Test func unknownTagsRemainAsTextUntilAccepted() {
        var text = "Comprar #Casa y #CASA con #Mamá"
        var tags: [TaskTag] = []
        let unknown = TagSyntax.extract(from: &text, tags: &tags, available: [])
        #expect(unknown == ["Casa", "Mamá"])
        #expect(text == "Comprar #Casa y #CASA con #Mamá")
        let home = TaskTag(name: "Casa")
        _ = TagSyntax.extract(from: &text, tags: &tags, available: [home])
        #expect(text == "Comprar y con #Mamá")
        #expect(tags.count == 1)
    }

    @Test func validatesNamesAndIgnoresURLFragments() {
        #expect(TagSyntax.validName("Vídeo_2026"))
        #expect(!TagSyntax.validName("Dos palabras"))
        #expect(!TagSyntax.validName(""))
        #expect(TagSyntax.key("CAFÉ") == TagSyntax.key("cafe\u{301}"))
        #expect(TagSyntax.mentions(in: "https://example.com/#section abc#def (#Real)").map(\.name) == ["Real"])
    }

    @Test func persistsRenameColorAndRelationshipsAcrossContexts() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tags-\(UUID()).store")
        let schema = Schema([TaskItem.self, TaskTag.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let context = ModelContext(container)
        let tag = TaskTag(name: "Trabajo")
        let task = TaskItem(title: "Preparar reunión")
        context.insert(task)
        context.insert(tag)
        task.tags = [tag]
        try context.save()
        tag.name = "Oficina"
        tag.color = .red
        try context.save()
        let fresh = ModelContext(container)
        let saved = try #require(fresh.fetch(FetchDescriptor<TaskItem>()).first)
        #expect(saved.tags?.first?.name == "Oficina")
        #expect(saved.tags?.first?.red == tag.red)
        #expect(saved.tags?.first?.blue == tag.blue)
    }

    @Test func deletingTagKeepsTasksAndDeletingTaskKeepsTag() throws {
        let container = try ModelContainer(for: TaskItem.self, TaskTag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let tag = TaskTag(name: "Trabajo")
        let task = TaskItem(title: "Reunión")
        context.insert(tag)
        context.insert(task)
        task.tags = [tag]
        try context.save()
        context.delete(tag)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<TaskItem>()) == 1)
        #expect(task.tags?.isEmpty != false)
        let other = TaskTag(name: "Casa")
        context.insert(other)
        task.tags = [other]
        try context.save()
        context.delete(task)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<TaskTag>()) == 1)
    }
}
