import SwiftUI
import SwiftData

struct TaggedTaskEditor: View {
    @Environment(\.modelContext) private var context
    @Query private var available: [TaskTag]
    @Binding var text: String
    @Binding var tags: [TaskTag]
    var completed = false
    var multiline = true
    var onCommit: () -> Void = {}
    @State private var focused = false
    @State private var unknown: [String] = []
    @State private var showingPrompt = false
    @State private var resolving = false
    @State private var saveError: String?

    var body: some View {
        InlineTaggedTextView(text: $text, tags: $tags, focused: $focused,
                             completed: completed, multiline: multiline,
                             onSubmit: finishEditing)
        .onChange(of: focused) { wasFocused, isFocused in
            if wasFocused && !isFocused { finishEditing() }
        }
        .alert("Crear etiqueta", isPresented: $showingPrompt) {
            Button("Crear") { resolve(create: true) }
            Button("Cancelar", role: .cancel) { resolve(create: false) }
        } message: {
            Text("¿Quieres crear #\(unknown.first ?? "")? Se creará en cian. Podrás cambiar su color en Etiquetas.")
        }
        .alert("No se pudo guardar", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("Aceptar", role: .cancel) { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private func finishEditing() {
        guard !resolving else { return }
        resolving = true
        unknown = TagSyntax.extract(from: &text, tags: &tags, available: available)
        next()
    }

    private func resolve(create: Bool) {
        guard let name = unknown.first else { return }
        if create {
            let tag = available.first { TagSyntax.key($0.name) == TagSyntax.key(name) } ?? TaskTag(name: name)
            if tag.modelContext == nil { context.insert(tag) }
            _ = TagSyntax.extract(from: &text, tags: &tags, available: [tag])
        }
        unknown.removeFirst()
        // Let the current alert finish dismissing before presenting the next one.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            next()
        }
    }

    private func next() {
        if unknown.isEmpty {
            onCommit()
            do { try context.save() } catch { saveError = error.localizedDescription }
            resolving = false
        } else {
            showingPrompt = true
        }
    }
}

