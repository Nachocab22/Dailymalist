//
//  Habit.swift
//  Dailymalist
//
//  Created by Nachete on 30/06/2026.
//

import SwiftData
import Foundation

enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var icon: String
    var repetitionDays: [Weekday]
    var isActive: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade,
                  inverse: \HabitCompletion.habit
    )
    var completions: [HabitCompletion] = []
    
    init(id: UUID = UUID(),
         title: String,
         icon: String,
         repetitionDays: [Weekday],
         isActive: Bool = true,
         createdAt: Date = .now
        )
    {
        self.id = id
        self.title = title
        self.icon = icon
        self.repetitionDays = repetitionDays
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

extension Habit {
    func isScheduled(
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let weekdayNumber = calendar.component(.weekday, from: date)

        guard let weekday = Weekday(rawValue: weekdayNumber) else {
            return false
        }

        return repetitionDays.contains(weekday)
    }

    func completion(
        on date: Date,
        calendar: Calendar = .current
    ) -> HabitCompletion? {
        let requestedDay = calendar.startOfDay(for: date)

        return completions.first {
            calendar.isDate($0.day, inSameDayAs: requestedDay)
        }
    }
    
    @MainActor
    func toggleCompletion(
        on date: Date,
        in modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        let existingCompletions = completions.filter {
            calendar.isDate($0.day, inSameDayAs: date)
        }

        if !existingCompletions.isEmpty {
            let ids = Set(existingCompletions.map(\.id))

            completions.removeAll { ids.contains($0.id) }

            for completion in existingCompletions {
                modelContext.delete(completion)
            }
        } else {
            let newCompletion = HabitCompletion(
                day: date,
                calendar: calendar
            )

            modelContext.insert(newCompletion)

            completions.append(newCompletion)
        }
    }

    func isCompleted(
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        completion(on: date, calendar: calendar) != nil
    }
}
