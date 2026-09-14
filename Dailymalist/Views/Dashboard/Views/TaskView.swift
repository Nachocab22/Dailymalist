//
//  TaskView.swift
//  Dailymalist
//
//  Created by Nachete on 27/06/2026.
//

import SwiftUI
import SwiftData

struct TaskView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var priorityTasks: [TaskItem]
    @Query private var tasks: [TaskItem]
    
    @State private var newTaskTitle = ""
    @State private var showsCompletedPriorityTasks = false
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isNewTaskFocused: Bool
    private let day: Date

    init(
        day: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let startOfDay = calendar.startOfDay(for: day)
        self.day = startOfDay

        let startOfNextDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: startOfDay
        )!

        let priorityPredicate = #Predicate<TaskItem> { task in
            task.deletedAt == nil &&
            task.isPriority &&
            task.scheduledFor >= startOfDay &&
            task.scheduledFor < startOfNextDay
        }

        let normalPredicate = #Predicate<TaskItem> { task in
            task.deletedAt == nil &&
            !task.isPriority &&
            task.scheduledFor >= startOfDay &&
            task.scheduledFor < startOfNextDay
        }

        _priorityTasks = Query(
            filter: priorityPredicate,
            sort: \TaskItem.completedAt,
            order: .forward
        )

        _tasks = Query(
            filter: normalPredicate,
            sort: \TaskItem.completedAt,
            order: .forward
        )
    }
    
    var body: some View {
        
        VStack(alignment: .leading){
            Text("Tareas")
                .font(Font.system(size: 30, weight: .semibold))
                .padding()
            List {
                if !priorityTasks.isEmpty {
                    priorityHeader
                        .modifier(PriorityCardRow(position: .top))

                    ForEach(pendingPriorityTasks) { task in
                        TaskRow(task: task)
                            .padding(.vertical, 8)
                            .modifier(PriorityCardRow(position: .middle))
                    }
                    
                    if(pendingPriorityTasks.count == 0){
                        Text("TODO COMPLETADO 🎉")
                            .font(Font.system(size: 16, weight: .semibold))
                            .foregroundStyle(.gray)
                            .modifier(PriorityCardRow(position: .middle))
                    }

                    if showsCompletedPriorityTasks {
                        ForEach(completedPriorityTasks) { task in
                            TaskRow(task: task)
                                .padding(.vertical, 6)
                                .modifier(PriorityCardRow(position: .middle))
                        }
                    }

                    priorityFooter
                        .modifier(PriorityCardRow(position: .bottom))
                }
                if !priorityTasks.isEmpty && !tasks.isEmpty {
                    Text("Otras tareas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                ForEach(tasks) { task in
                    TaskRow(task: task)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                HStack(alignment: .firstTextBaseline){
                    Image(systemName: "circle.dotted").opacity(0.5)
                        .font(.title2)
                    TextField("", text: $newTaskTitle)
                        .focused($isNewTaskFocused)
                        .onSubmit {
                            addNewTask()
                        }
                        .onChange(of: isNewTaskFocused) { oldValue, newValue in
                            if oldValue == true && newValue == false {
                                addNewTask()
                            }
                        }
                }.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
            }.listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(Color.clear)
            
        }
    }
    
    private var pendingPriorityTasks: [TaskItem] {
        priorityTasks.filter { !$0.isCompleted }
    }

    private var completedPriorityTasks: [TaskItem] {
        priorityTasks.filter(\.isCompleted)
    }

    private var priorityHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                priorityTitle
                Spacer(minLength: 12)
                pendingCount
            }
            VStack(alignment: .leading, spacing: 6) {
                priorityTitle
                pendingCount
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var priorityTitle: some View {
        Label("Destacadas", systemImage: "star")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(colorScheme == .dark
                ? Color(red: 0.89, green: 0.78, blue: 0.49)
                : Color(red: 0.53, green: 0.39, blue: 0.13))
    }

    private var pendingCount: some View {
        Text(pendingPriorityTasks.count == 1
             ? "1 pendiente" : "\(pendingPriorityTasks.count) pendientes")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var priorityFooter: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !completedPriorityTasks.isEmpty {
                Divider().overlay(.primary.opacity(0.03))
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsCompletedPriorityTasks.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showsCompletedPriorityTasks
                              ? "chevron.up" : "chevron.down")
                        Text(completedPriorityTasks.count == 1
                             ? "1 completada" : "\(completedPriorityTasks.count) completadas")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(showsCompletedPriorityTasks ? "Desplegado" : "Plegado")
            }
        }
        .padding(.bottom, 12)
    }

    private func addNewTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty else { return }
        
        modelContext.insert(TaskItem(title: title, scheduledFor: day))
        newTaskTitle = ""
    }
    
}

#Preview {
    TaskView()
}

struct TaskRow: View {
    
    @Bindable var task: TaskItem
    
    @State private var isCalendarShown = false
    @State private var dateSelected = Date()
    
    var body: some View {
        HStack {
            Button(action: {
                if (task.completedAt == nil) {
                    task.completedAt = .now
                } else {
                    task.completedAt = nil
                }
                    
            }) {
                Image(systemName: task.completedAt != nil ? "inset.filled.circle" : "circle").foregroundStyle(task.completedAt != nil ? task.isPriority ? .orange : .blue : .primary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Marcar como pendiente" : "Completar tarea")
            .accessibilityValue(task.title)
            TextField(task.title, text: $task.title, axis: .vertical)
                .font(Font.system(size: 18))
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .lineLimit(nil)
                
                
        }.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                task.deletedAt = .now
            } label: {
                Label("Eliminar", systemImage: "trash"
                )
            }.tint(.red)
            Button {
                task.isPriority.toggle()
            } label: {
                Label(
                    task.isPriority ? "No urgente" : "Urgente",
                    systemImage: task.isPriority ? "xmark.octagon" : "exclamationmark.octagon"
                )
            }.tint(task.isPriority ? .gray : .orange)
        }.swipeActions(edge: .leading, allowsFullSwipe: false){
            Button {
                dateSelected = task.scheduledFor
                isCalendarShown = true
            } label: {
                Label("Posponer", systemImage: "chevron.forward.2"
                )
            }.tint(.blue)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .popover(isPresented: $isCalendarShown) {
                VStack {
                    DatePicker(
                        "Nueva fecha",
                        selection: $dateSelected,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)

                    HStack {
                        Button("Cancelar") {
                            isCalendarShown = false
                        }

                        Spacer()

                        Button("Reprogramar") {
                            task.reschedule(to: dateSelected)
                            isCalendarShown = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(width: 330)
                .presentationCompactAdaptation(.popover)
            }
    }
    
    func posponeTask(task: TaskItem) {
        
    }
}

// Separate List rows preserve native swipe actions while sharing one card surface.
private struct PriorityCardRow: ViewModifier {
    enum Position { case top, middle, bottom }
    let position: Position
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 0, trailing: 28))
            .listRowBackground(
                UnevenRoundedRectangle(
                    topLeadingRadius: position == .top ? 16 : 0,
                    bottomLeadingRadius: position == .bottom ? 16 : 0,
                    bottomTrailingRadius: position == .bottom ? 16 : 0,
                    topTrailingRadius: position == .top ? 16 : 0
                )
                .fill(colorScheme == .dark
                      ? Color(red: 0.20, green: 0.19, blue: 0.14)
                      : Color(red: 0.98, green: 0.91, blue: 0.73))
                .padding(.horizontal, 8)
            )
    }
}
