//
//  HabitView.swift
//  Dailymalist
//
//  Created by Nachete on 27/06/2026.
//

import SwiftUI
import SwiftData

struct HabitView: View {
    
    @Environment(\.modelContext) private var modelContext
    public var isPortrait: Bool
    private let day: Date
    private let calendar: Calendar
    
    
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isActive
        },
        sort: \Habit.createdAt,
        order: .reverse
    ) private var activeHabits: [Habit]
    
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isActive == false
        },
        sort: \Habit.createdAt,
        order: .reverse
    ) private var archivedHabits: [Habit]
    
    @Query private var allHabits: [Habit]
    
    private var todayHabits: [Habit] {
        activeHabits.filter { habit in
            habit.createdAt < day &&
            habit.isScheduled(
                on: day,
                calendar: calendar
            )
        }
    }

    init(
        isPortrait: Bool,
        day: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.isPortrait = isPortrait
        self.day = day
        self.calendar = calendar
    }
    
    ///Campos Form nuevo habito
    @State private var newHabitTitle: String = ""
    @State private var newHabitIcon: String = ""
    @State private var habitRepetitions: [String] = []
    @State private var isNewHabitModalShown: Bool = false
    @State private var habitBeingEdited: Habit?
    @State private var isAlertShown: Bool = false
    
    ///Campos Form detalle habitos
    @State private var isDetailModalShown : Bool = false
    
    ///Campos Alert
    @State private var duplicateMessage = ""
    @State private var habitToUnarchive: Habit?
    
    //Campos ocultar archivo vertical
    @State private var visibleArchiveHabitID: UUID?
    @State private var archiveHideTask: Task<Void, Never>?

    let weekIcons: [String] = [
        "l.circle",
        "m.circle",
        "x.circle",
        "j.circle",
        "v.circle",
        "s.circle",
        "d.circle",
    ]
    ///Fin Campos Form
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Button{
                isDetailModalShown = true
            } label: {
                Text("Hábitos")
                    .font(Font.system(size: 30, weight: .semibold))
                Image(systemName: "arrow.up.forward.square")
                    .font(.headline)
                    .foregroundStyle(.gray)
            }
            .padding()
            .buttonStyle(.plain)
                
                if(isPortrait){ ///Vista vertical
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(alignment: .center, spacing: 10){
                            ForEach(todayHabits){ habit in
                                HStack(spacing: 8) {
                                    Button{
                                        showArchiveButton(for: habit)
                                    } label: {
                                        Image(systemName: habit.icon).font(.largeTitle)
                                    }.buttonStyle(.plain)
                                        .accessibilityLabel("Mostrar opción de pausar \(habit.title)")
                                    
                                    Button {
                                        habit.toggleCompletion(
                                            on: day,
                                            in: modelContext,
                                            calendar: calendar
                                        )
                                    } label: {
                                        Image(
                                            systemName: habit.isCompleted(
                                                on: day,
                                                calendar: calendar
                                            ) ? "inset.filled.circle" : "circle"
                                        )
                                        .foregroundStyle(
                                            habit.isCompleted(
                                                on: day,
                                                calendar: calendar
                                            ) ? .blue : .primary
                                        )
                                        .font(.title)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                    }
                                }
                                .padding()
                                .background(habit.isCompleted(
                                    on: day,
                                    calendar: calendar
                                ) ? .blue.opacity(0.2) : .gray.opacity(0.2))
                                .clipShape(Capsule())
                                .overlay(alignment: .topLeading) {
                                    if visibleArchiveHabitID == habit.id {
                                        PauseUpperButton(habit: habit)
                                            .offset(x: -8, y: -8)
                                            .transition(
                                                .scale.combined(with: .opacity)
                                            )
                                    }
                                }
                            }
                            Button(action: {isNewHabitModalShown = true}){
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(.primary)
                                    .padding()
                                    .background(.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }.frame(maxWidth: .infinity, alignment: .center)
                    }
                    .scrollClipDisabled()
                    .onDisappear {
                        archiveHideTask?.cancel()
                    }
                    .padding(.horizontal, 20)
                } else { ///Vista Horizontal
                    VStack(alignment: .leading, spacing: 10){
                        List {
                            ForEach(todayHabits) { habit in
                                HStack(spacing: 8) {
                                    Button {
                                        habit.toggleCompletion(
                                            on: day,
                                            in: modelContext,
                                            calendar: calendar
                                        )
                                    } label: {
                                        Image(
                                            systemName: habit.isCompleted(
                                                on: day,
                                                calendar: calendar
                                            )
                                            ? "inset.filled.circle": "circle"
                                        )
                                        .foregroundStyle(
                                            habit.isCompleted(
                                                on: day,
                                                calendar: calendar
                                            )
                                            ? .blue: .primary
                                        )
                                        .font(.title)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Image(systemName: habit.icon)
                                        .font(.largeTitle)
                                    
                                    Text(habit.title)
                                        .font(.title2)
                                }
                                .padding()
                                .background(habit.isCompleted(
                                    on: day,
                                    calendar: calendar
                                ) ? .blue.opacity(0.2) : Color.clear)
                                .clipShape(Capsule())
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        habit.isActive = false
                                    } label: {
                                        Label("Pausar", systemImage: "pause.fill")
                                    }
                                    .tint(.yellow)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            Button(action: {isNewHabitModalShown = true}){
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundStyle(.primary)
                                Text("Nuevo hábito")
                            }.buttonStyle(.plain)
                                .padding(.vertical, 10)
                                .padding(.trailing, 20)
                                .padding(.leading)
                                .background(.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .padding(.horizontal, 20)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        
                    }    
                }
        }
        //Modal nuevo hábito
        .sheet(isPresented: $isNewHabitModalShown, onDismiss: resetHabitForm) {
            NavigationStack {
                HabitFormView(
                    newHabitTitle: $newHabitTitle,
                    newHabitIcon: $newHabitIcon,
                    habitRepetitions: $habitRepetitions,
                    isEditing: habitBeingEdited != nil,
                    weekIcons: weekIcons,
                    onSave: { createNewHabit() }
                )
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hecho") {
                            isNewHabitModalShown = false
                        }
                    }
                }
            }
            
            ///Fin Modal nuevo hábito
            ///Alerta
            .alert("Posible hábito duplicado", isPresented: $isAlertShown) {
                Button("Cancelar", role: .cancel) {
                    habitToUnarchive = nil
                }

                if let habit = habitToUnarchive {
                    Button("Activar «\(habit.title)»") {
                        habit.isActive = true

                        newHabitTitle = ""
                        newHabitIcon = ""
                        habitRepetitions = []
                        habitToUnarchive = nil
                        isNewHabitModalShown = false
                    }
                }

                Button("Crear igualmente") {
                    habitToUnarchive = nil
                    createNewHabit(ignoreDuplicates: true)
                }
            } message: {
                Text(duplicateMessage)
            }
            ///Fin Alerta
            .presentationDetents([.large])
            
        }
        .padding(.top, isPortrait ? 20 : 0)
        .padding(.bottom, 20)
        ///Modal detalle hábitos
        .sheet(isPresented: $isDetailModalShown, onDismiss: {
            // Espera a que se cierre el detalle antes de abrir el formulario.
            if habitBeingEdited != nil {
                isNewHabitModalShown = true
            }
        }, content: {
            NavigationStack{
                List{
                    Section(header: Text("Activos")){
                        activeHabits.isEmpty ? Text("No tienes ningún hábito activo").foregroundColor(.secondary) : nil
                        ForEach(activeHabits) { activeHabit in
                            HabitDetailElement(habit: activeHabit)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        modifyHabit(habit: activeHabit)
                                    } label: {
                                        Label("Modificar", systemImage: "pencil.line")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                    Section(header: Text("Pausados")) {
                        archivedHabits.isEmpty ? Text("No tienes ningún hábito archivado").foregroundColor(.secondary) : nil
                        ForEach(archivedHabits) { archivedHabit in
                            HabitDetailElement(habit: archivedHabit)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    modelContext.delete(archivedHabit)
                                } label: {
                                    Label("Eliminar", systemImage: "trash.fill")
                                }
                                .tint(.red)
                                Button {
                                    modifyHabit(habit: archivedHabit)
                                } label: {
                                    Label("Modificar", systemImage: "pencil.line")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .navigationTitle("Hábitos")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hecho") {
                            isDetailModalShown = false
                        }
                    }
                }
            }
            
        })
        ///Fin Modal detalle hábitos
    }
    
    private func createNewHabit(ignoreDuplicates: Bool = false) {
        
        let title = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        let selectedDays: [Weekday] = habitRepetitions.compactMap { icon in
                switch icon {
                case "l.circle": return .monday
                case "m.circle": return .tuesday
                case "x.circle": return .wednesday
                case "j.circle": return .thursday
                case "v.circle": return .friday
                case "s.circle": return .saturday
                case "d.circle": return .sunday
                default: return nil
                }
            }

        guard !selectedDays.isEmpty else { return }

        if let habit = habitBeingEdited {
            habit.title = title
            habit.icon = newHabitIcon.isEmpty ? "star.fill" : newHabitIcon
            habit.repetitionDays = selectedDays
            isNewHabitModalShown = false
            return
        }
        
        if !ignoreDuplicates {
            let matches = allHabits.filter {
                areSimilar($0.title, title)
            }
            
            habitToUnarchive = matches.first { !$0.isActive }

            if !matches.isEmpty {
                let details = matches.prefix(3).map { habit in
                    let status = habit.isActive ? "activo" : "archivado"
                    return "• \(habit.title) (\(status))"
                }
                .joined(separator: "\n")

                let extra = matches.count > 3
                    ? "\nY \(matches.count - 3) más."
                    : ""

                duplicateMessage = """
                Ya tienes hábitos con títulos iguales o parecidos:

                \(details)\(extra)

                ¿Deseas crear el hábito igualmente?
                """

                isAlertShown = true
                return
            }
        }
        
        modelContext.insert(
            Habit(
                title: title,
                icon: newHabitIcon.isEmpty ? "star.fill" : newHabitIcon,
                repetitionDays: selectedDays
            )
        )
        
        newHabitTitle = ""
        newHabitIcon = ""
        habitRepetitions = []
        isNewHabitModalShown = false
    }
    
    private func modifyHabit(habit: Habit) {
        habitBeingEdited = habit
        newHabitTitle = habit.title
        newHabitIcon = habit.icon
        habitRepetitions = habit.repetitionDays.map { day in
            switch day {
            case .monday: return "l.circle"
            case .tuesday: return "m.circle"
            case .wednesday: return "x.circle"
            case .thursday: return "j.circle"
            case .friday: return "v.circle"
            case .saturday: return "s.circle"
            case .sunday: return "d.circle"
            }
        }

        if isDetailModalShown {
            isDetailModalShown = false
        } else {
            isNewHabitModalShown = true
        }
    }

    private func resetHabitForm() {
        habitBeingEdited = nil
        newHabitTitle = ""
        newHabitIcon = ""
        habitRepetitions = []
        habitToUnarchive = nil
        duplicateMessage = ""
        isAlertShown = false
    }

    private func showArchiveButton(for habit: Habit) {
        archiveHideTask?.cancel()

        withAnimation(.snappy) {
            visibleArchiveHabitID = habit.id
        }

        archiveHideTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                // La tarea se canceló porque se tocó otro icono.
                return
            }

            guard visibleArchiveHabitID == habit.id else {
                return
            }

            withAnimation(.snappy) {
                visibleArchiveHabitID = nil
            }
        }
    }
    
    private func keywords(from title: String) -> Set<String> {
        let normalized = title.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "es_ES")
        )

        let ignoredWords: Set<String> = [
            "a", "al", "de", "del", "el", "la", "los", "las",
            "un", "una", "unos", "unas", "y", "o",
            "en", "con", "para", "por", "salir"
        ]

        let words = normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map { String($0) }
            .filter { !ignoredWords.contains($0) }

        return Set(words)
    }

    private func areSimilar(_ first: String, _ second: String) -> Bool {
        let trimmedFirst = first.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecond = second.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedFirst.compare(
            trimmedSecond,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) == .orderedSame {
            return true
        }

        let firstWords = keywords(from: first)
        let secondWords = keywords(from: second)

        guard !firstWords.isEmpty, !secondWords.isEmpty else {
            return false
        }

        let sharedWords = firstWords.intersection(secondWords).count
        let smallerCount = min(firstWords.count, secondWords.count)

        return Double(sharedWords) / Double(smallerCount) >= 0.75
    }
    
}


private struct HabitFormView: View {
    @Binding var newHabitTitle: String
    @Binding var newHabitIcon: String
    @Binding var habitRepetitions: [String]
    let isEditing: Bool
    let weekIcons: [String]
    let onSave: () -> Void

    private var displayedIconName: String {
        newHabitIcon.isEmpty ? "star.fill" : newHabitIcon
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Título")
                    .font(.title)

                TextField("Introduce el hábito", text: $newHabitTitle)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .padding(12)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Icono")
                    .font(.title)

                NavigationLink {
                    HabitIconPickerView(selectedIconName: $newHabitIcon)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: displayedIconName)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(.blue.opacity(0.15), in: Circle())
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(HabitIconCatalog.icon(named: displayedIconName)?.displayName ?? "Icono actual")
                                .foregroundStyle(.primary)
                            Text("Elegir icono")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                    .padding(12)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Elegir icono. Selección actual: \(HabitIconCatalog.icon(named: displayedIconName)?.displayName ?? "icono personalizado")")

                Text("Repeticiones")
                    .font(.title)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 44), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(weekIcons, id: \.self) { weekDayIcon in
                        repetitionButton(for: weekDayIcon)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isEditing ? "Editar hábito" : "Nuevo hábito")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onSave()
            } label: {
                Text(isEditing ? "Guardar cambios" : "Crear hábito")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private func repetitionButton(for weekDayIcon: String) -> some View {
        let isSelected = habitRepetitions.contains(weekDayIcon)

        return Button {
            if isSelected {
                habitRepetitions.removeAll { $0 == weekDayIcon }
            } else {
                habitRepetitions.append(weekDayIcon)
            }
        } label: {
            Image(systemName: isSelected ? weekDayIcon + ".fill" : weekDayIcon)
                .font(.largeTitle)
                .foregroundStyle(isSelected ? .blue : .primary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(weekdayName(for: weekDayIcon)), \(isSelected ? "seleccionado" : "no seleccionado")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func weekdayName(for iconName: String) -> String {
        switch iconName {
        case "l.circle": "Lunes"
        case "m.circle": "Martes"
        case "x.circle": "Miércoles"
        case "j.circle": "Jueves"
        case "v.circle": "Viernes"
        case "s.circle": "Sábado"
        case "d.circle": "Domingo"
        default: "Día"
        }
    }
}

private struct HabitIconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIconName: String
    @State private var searchText = ""
    @State private var selectedCategory: HabitIconCategory?

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 12)
    ]

    private var filteredIcons: [HabitIcon] {
        HabitIconCatalog.icons.filter { icon in
            (selectedCategory == nil || icon.category == selectedCategory)
                && icon.matches(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryFilter

                if filteredIcons.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredIcons) { icon in
                            iconButton(icon)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Elegir icono")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Buscar iconos")
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton(title: "Todas", category: nil)

                ForEach(HabitIconCategory.allCases) { category in
                    categoryButton(title: category.rawValue, category: category)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func categoryButton(
        title: String,
        category: HabitIconCategory?
    ) -> some View {
        let isSelected = selectedCategory == category

        return Button(title) {
            selectedCategory = category
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 14)
        .frame(minHeight: 36)
        .background(
            isSelected ? Color.accentColor : Color.gray.opacity(0.12),
            in: Capsule()
        )
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func iconButton(_ icon: HabitIcon) -> some View {
        let isSelected = selectedIconName == icon.symbolName

        return Button {
            selectedIconName = icon.symbolName
            dismiss()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon.symbolName)
                    .font(.title)
                    .frame(height: 32)
                    .accessibilityHidden(true)

                Text(icon.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? .blue : .primary)
            .frame(maxWidth: .infinity, minHeight: 82)
            .padding(6)
            .background(
                isSelected ? .blue.opacity(0.15) : .gray.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.displayName)
        .accessibilityValue(isSelected ? "Seleccionado" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PauseUpperButton: View {
    
    @Bindable var habit: Habit
    
    var body: some View {
        Button {
            habit.isActive = false
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
                .background(.yellow, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pausar hábito")

    }
}

struct HabitDetailElement: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var habit: Habit
    
    var body: some View {
        HStack{
            Image(systemName: habit.icon)
                .font(.title)

            Text(habit.title)
                .font(.title2)

            Spacer()

            Button {
                habit.isActive.toggle()
            } label: {
                Image(systemName: habit.isActive ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        (habit.isActive ? Color.yellow : Color.green),
                        in: Circle()
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(habit.isActive ? "Pausar" : "Activar") hábito \(habit.title)")
        }
    }
    
}

#Preview {
    HabitView(isPortrait: true)
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
