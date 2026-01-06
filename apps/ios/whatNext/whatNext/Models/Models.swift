//
//  Models.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import Foundation

enum MealEvent: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

struct Meal: Identifiable, Codable {
    var id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var mealEvent: MealEvent
    var occurredAt: Date
    
    init(id: UUID = UUID(), name: String, hour: Int, minute: Int, mealEvent: MealEvent, occurredAt: Date = Date()) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.mealEvent = mealEvent
        self.occurredAt = occurredAt
    }
    
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

struct Recommendation {
    var food: String
    var reason: String
    var ingredients: [String]
    var steps: [String]
    
    static let placeholder = Recommendation(
        food: "Tap to get a recommendation",
        reason: "",
        ingredients: [],
        steps: []
    )
}
