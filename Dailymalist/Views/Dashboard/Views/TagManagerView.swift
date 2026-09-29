import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskTag.name) private var tags: [TaskTag]
    @State private var name = ""
    @State private var color: Color = .cyan
    @State private var editing: TaskTag?
    @State private var deleting: TaskTag?
    @State private var error: String?
    @State private var showingForm = false
    @State private var newName = ""
    @FocusState private var newNameFocused: Bool

    private var cleanName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
    }

    var body: some View {
        NavigationStack {
            List {
                if tags.isEmpty {
                    Text("Todavía no hay etiquetas. Escribe una abajo para crearla.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tags) { tag in
                    HStack {
                        Button {
                            editing = tag
                            name = tag.name
                            color = tag.color
                            showingForm = true
                        } label: {
                            Text("#\(tag.name)")
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        ColorPicker("Color de #\(tag.name)", selection: Binding(
                            get: { tag.color },
                            set: { value in
                                tag.color = value
                                if editing?.id == tag.id { color = value }
                                save()
                            }
                        ), supportsOpacity: false)
                        .labelsHidden()
                        Button(role: .destructive) { deleting = tag } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Eliminar #\(tag.name)")
                    }
                }
                HStack {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                    TextField("Nueva etiqueta", text: $newName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($newNameFocused)
                        .onSubmit { createInline() }
                        .onChange(of: newNameFocused) { old, new in
                            if old && !new { createInline() }
                        }
                }


            }
            .scrollContentBackground(.hidden)
            .background(.white)
            .navigationTitle("Etiquetas")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        if createInline() { dismiss() }
                    }
                }
            }
            .navigationDestination(isPresented: $showingForm) {
                tagForm
            }
            .alert("Eliminar etiqueta", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Eliminar", role: .destructive) {
                    guard let tag = deleting else { return }
                    if editing?.id == tag.id { reset() }
                    context.delete(tag)
                    deleting = nil
                    save()
                }
                Button("Cancelar", role: .cancel) { deleting = nil }
            } message: { Text("Se quitará de todas las tareas. Las tareas se conservarán.") }
            .alert("No se pudo guardar", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Aceptar", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.light)
        .presentationBackground(.white)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var tagForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nombre")
                    .font(.title)
                TextField("Introduce la etiqueta", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .padding(12)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Color")
                    .font(.title)
                ColorPicker("Elegir color", selection: $color, supportsOpacity: false)
                    .padding(12)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Usa letras, números o guiones bajos, sin espacios.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(.white)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(editing == nil ? "Nueva etiqueta" : "Editar etiqueta")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: submit) {
                Text(editing == nil ? "Crear etiqueta" : "Guardar cambios")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!TagSyntax.validName(cleanName))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    @discardableResult private func createInline() -> Bool {
        guard error == nil else { return false }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard !candidate.isEmpty else { return true }
        guard TagSyntax.validName(candidate) else {
            error = "Usa letras, números o guiones bajos, sin espacios."
            return false
        }
        guard !tags.contains(where: { TagSyntax.key($0.name) == TagSyntax.key(candidate) }) else {
            error = "Ya existe una etiqueta con ese nombre."
            return false
        }
        let tag = TaskTag(name: candidate)
        context.insert(tag)
        if save() { newName = ""; return true }
        context.delete(tag)
        return false
    }

    private func submit() {
        guard TagSyntax.validName(cleanName) else { return }
        guard !tags.contains(where: { $0.id != editing?.id && TagSyntax.key($0.name) == TagSyntax.key(cleanName) }) else {
            error = "Ya existe una etiqueta con ese nombre."
            return
        }
        if let editing {
            editing.name = cleanName
            editing.color = color
        } else {
            context.insert(TaskTag(name: cleanName, color: color))
        }
        if save() { showingForm = false }
    }

    @discardableResult private func save() -> Bool {
        do { try context.save(); return true }
        catch { self.error = error.localizedDescription; return false }
    }

    private func reset() { editing = nil; name = ""; color = .cyan }
}
