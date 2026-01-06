//
//  APIService.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    // TODO: Update with actual backend URL
    private let baseURL = "http://localhost:3000"
    
    private init() {}
    
    func fetchRecommendation(for meals: [Meal]) async throws -> Recommendation {
        // For now, generate a local recommendation based on meal patterns
        // TODO: Replace with actual API call when backend endpoint is ready
        
        try await Task.sleep(nanoseconds: 800_000_000) // Simulate network delay
        
        return generateLocalRecommendation(from: meals)
    }
    
    // MARK: - Local Recommendation Logic (temporary until backend is wired)
    
    private func generateLocalRecommendation(from meals: [Meal]) -> Recommendation {
        let recentMeals = Array(meals.prefix(10))
        let mealNames = recentMeals.map { $0.name.lowercased() }
        
        // Detect patterns
        let hasProtein = mealNames.contains { $0.contains("chicken") || $0.contains("beef") || $0.contains("fish") || $0.contains("egg") || $0.contains("tofu") }
        let hasCarbs = mealNames.contains { $0.contains("rice") || $0.contains("pasta") || $0.contains("bread") || $0.contains("noodle") }
        let hasVeggies = mealNames.contains { $0.contains("salad") || $0.contains("vegetable") || $0.contains("broccoli") || $0.contains("spinach") }
        
        // Simple recommendation logic
        let suggestions: [(food: String, reason: String, ingredients: [String], steps: [String])] = [
            (
                food: "Stir-Fry Bowl",
                reason: "A balanced mix based on your recent meals. Quick, nutritious, and satisfying.",
                ingredients: ["Protein of choice", "Mixed vegetables", "Soy sauce", "Garlic", "Rice or noodles"],
                steps: ["Cook rice or noodles", "Sauté garlic and protein", "Add vegetables and sauce", "Serve over base"]
            ),
            (
                food: "Mediterranean Bowl",
                reason: "Light and fresh — a nice change of pace from your recent meals.",
                ingredients: ["Quinoa", "Cucumber", "Tomatoes", "Feta", "Olive oil", "Lemon"],
                steps: ["Cook quinoa", "Chop vegetables", "Combine and drizzle with olive oil", "Add feta and lemon"]
            ),
            (
                food: "Simple Omelette",
                reason: "Quick protein boost. Works great any time of day.",
                ingredients: ["Eggs", "Cheese", "Vegetables of choice", "Butter", "Salt & pepper"],
                steps: ["Whisk eggs", "Melt butter in pan", "Pour eggs and add fillings", "Fold and serve"]
            ),
            (
                food: "Grain Bowl",
                reason: "Hearty and customizable based on what you have.",
                ingredients: ["Brown rice or quinoa", "Roasted vegetables", "Protein", "Tahini or sauce"],
                steps: ["Cook grain base", "Roast vegetables", "Assemble bowl", "Drizzle with sauce"]
            )
        ]
        
        // Pick based on what's missing or varied
        let index: Int
        if !hasVeggies {
            index = 1 // Mediterranean
        } else if !hasProtein {
            index = 2 // Omelette
        } else if !hasCarbs {
            index = 3 // Grain bowl
        } else {
            index = Int.random(in: 0..<suggestions.count)
        }
        
        let pick = suggestions[index]
        return Recommendation(
            food: pick.food,
            reason: pick.reason,
            ingredients: pick.ingredients,
            steps: pick.steps
        )
    }
}

