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
                ForEach(priorityTasks) { task in
                    TaskRow(task: task)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(
                            Rectangle()
                                .fill(.yellow.opacity(0.5))
                                .padding(.vertical, 0)
                                .padding(.horizontal, 8)
                        )
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
            .background(Color.clear)
            
        }
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
            }.buttonStyle(.plain)
            TextField(task.title, text: $task.title, axis: .vertical)
                .font(Font.system(size: 18))
                .strikethrough(task.isCompleted)
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
        }.frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
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
