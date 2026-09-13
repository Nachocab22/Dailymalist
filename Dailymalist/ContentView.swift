//
//  ContentView.swift
//  Dailymalist
//
//  Created by Nachete on 20/06/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DashboardView()
            .task {
                inspectStorage()
            }
    }

    private func inspectStorage() {
        #if DEBUG
        print("=== Diagnóstico Dailymalist ===")
        print("Bundle ID:", Bundle.main.bundleIdentifier ?? "Sin ID")

        for configuration in modelContext.container.configurations {
            print("Base de datos:", configuration.url.path)
            print("Solo memoria:", configuration.isStoredInMemoryOnly)
        }

        do {
            // Contexto independiente para consultar lo persistido.
            let context = ModelContext(modelContext.container)

            let tasks = try context.fetchCount(
                FetchDescriptor<TaskItem>()
            )
            let habits = try context.fetchCount(
                FetchDescriptor<Habit>()
            )
            let completions = try context.fetchCount(
                FetchDescriptor<HabitCompletion>()
            )

            print("Tareas:", tasks)
            print("Hábitos:", habits)
            print("Registros de hábitos:", completions)
        } catch {
            print("Error consultando la base:", String(reflecting: error))
        }
        #endif
    }
}

#Preview {
    ContentView()
}
