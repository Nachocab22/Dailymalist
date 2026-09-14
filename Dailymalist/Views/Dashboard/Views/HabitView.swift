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

    let iconos: [String] = [
        "figure.strengthtraining.traditional",
        "figure.run",
        "book.fill",
        "paintbrush.pointed.fill",
        "figure.jumprope",
        "figure.run.treadmill",
        "figure.walk",
        "sunrise.fill",
        "figure.pool.swim",
        "figure.fencing",
    ]
    
    let weekIcons: [String] = [
        "l.circle",
        "m.circle",
        "x.circle",
        "j.circle",
        "v.circle",
        "s.circle",
        "d.circle",
    ]
        
    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
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
                                    
                                    Button{
                                        habit.toggleCompletion(
                                                on: day,
                                                in: modelContext
                                            )
                                    } label: {
                                        Image(systemName: habit.isCompleted(on: day) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(habit.isCompleted(on: day) ? .blue : .primary)
                                            .font(.largeTitle)
                                    }
                                }
                                .padding()
                                .background(.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .overlay(alignment: .topLeading) {
                                    if visibleArchiveHabitID == habit.id {
                                        ArchiveUpperButton(habit: habit)
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
                                                ? "checkmark.square.fill": "square"
                                            )
                                            .foregroundStyle(
                                                habit.isCompleted(
                                                    on: day,
                                                    calendar: calendar
                                                )
                                                ? .blue: .primary
                                            )
                                            .font(.largeTitle)
                                        }
                                        .buttonStyle(.plain)

                                        Image(systemName: habit.icon)
                                            .font(.largeTitle)

                                        Text(habit.title)
                                            .font(.title2)
                                    }
                                    .padding(.vertical, 8)
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
                            
                        }
                    }
        }
        //Modal nuevo hábito
        .sheet(isPresented: $isNewHabitModalShown, onDismiss: resetHabitForm) {
            HabitFormView(
                newHabitTitle: $newHabitTitle,
                newHabitIcon: $newHabitIcon,
                habitRepetitions: $habitRepetitions,
                isEditing: habitBeingEdited != nil,
                iconos: iconos,
                weekIcons: weekIcons,
                columns: columns,
                onSave: { createNewHabit() }
            )
            ///Fin Modal nuevo hábito
            .padding(20)
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
        .padding(.vertical, 20)
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
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        activeHabit.isActive = false
                                    } label: {
                                        Label("Pausar", systemImage: "pause.fill")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                    Section(header: Text("Archivados")) {
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
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    archivedHabit.isActive = true
                                } label: {
                                    Label("Activar", systemImage: "play.fill")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
                .navigationTitle("Hábitos")
                
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
    let iconos: [String]
    let weekIcons: [String]
    let columns: [GridItem]
    let onSave: () -> Void

    // Incluye también los iconos guardados que no estén en el catálogo actual.
    private var availableIcons: [String] {
        guard !newHabitIcon.isEmpty, !iconos.contains(newHabitIcon) else {
            return iconos
        }
        return iconos + [newHabitIcon]
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Título")
                    .font(.title)

                TextField("Introduce el hábito", text: $newHabitTitle)
                    .padding(12)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    

                Text("Icono")
                    .font(.title)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(availableIcons, id: \.self) { icono in
                        Button {
                            newHabitIcon = icono
                        } label: {
                            Image(systemName: icono)
                                .font(.title)
                                .foregroundStyle(newHabitIcon == icono ? .blue : .primary)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(newHabitIcon == icono ? .blue.opacity(0.15) : .gray.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Repeticiones")
                    .font(.title)

                HStack(spacing: 20) {
                    ForEach(weekIcons, id: \.self) { weekDayIcon in
                        Button {
                            if habitRepetitions.contains(weekDayIcon) {
                                habitRepetitions.removeAll { $0 == weekDayIcon }
                            } else {
                                habitRepetitions.append(weekDayIcon)
                            }
                        } label: {
                            Image(systemName: habitRepetitions.contains(weekDayIcon) ? weekDayIcon + ".fill" : weekDayIcon)
                                .font(.largeTitle)
                                .foregroundStyle(habitRepetitions.contains(weekDayIcon) ? .blue : .primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Button {
                    onSave()
                } label: {
                    Text(!isEditing ? "Crear hábito" : "Guardar cambios")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
    }
}

struct ArchiveUpperButton: View {
    
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
    
    @Bindable var habit: Habit
    
    var body: some View {
        HStack{
            Image(systemName: habit.icon)
                .font(.largeTitle)

            Text(habit.title)
                .font(.title2)
        }
    }
    
}

#Preview {
    HabitView(isPortrait: true)
}
