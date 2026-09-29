//
//  Item.swift
//  Dailymalist
//
//  Created by Nachete on 20/06/2026.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID

    var tags: [TaskTag]? = []

    var title: String
    var isPriority: Bool
    var scheduledFor: Date
    var postponementCount: Int

    var completedAt: Date?
    var deletedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        isPriority: Bool = false,
        scheduledFor: Date = .now,
        postponementCount: Int = 0,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.isPriority = isPriority
        self.scheduledFor = Calendar.current.startOfDay(for: scheduledFor)
        self.postponementCount = postponementCount
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.createdAt = createdAt
    }
}

extension TaskItem {
    var isCompleted: Bool {
        completedAt != nil
    }
    
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    func reschedule(
        to newDate: Date,
        calendar: Calendar = .current
    ) {
        let currentDay = calendar.startOfDay(for: scheduledFor)
        let newDay = calendar.startOfDay(for: newDate)
        
        guard newDay != currentDay else { return }
        
        if newDay > currentDay {
            postponementCount += 1
            }
        
        scheduledFor = newDay
    }
}
