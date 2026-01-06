//
//  MealStore.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import Foundation

@Observable
class MealStore {
    var meals: [Meal] = []
    var recommendation: Recommendation = .placeholder
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let storageKey = "savedMeals"
    
    init() {
        loadMeals()
    }
    
    func addMeal(_ meal: Meal) {
        meals.insert(meal, at: 0)
        saveMeals()
    }
    
    func deleteMeal(at offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
        saveMeals()
    }
    
    func getRecommendation() async {
        guard !meals.isEmpty else {
            recommendation = Recommendation(
                food: "Add some meals first!",
                reason: "I need to know what you've been eating to make a recommendation.",
                ingredients: [],
                steps: []
            )
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            recommendation = try await APIService.shared.fetchRecommendation(for: meals)
        } catch {
            errorMessage = error.localizedDescription
            recommendation = Recommendation(
                food: "Couldn't get recommendation",
                reason: error.localizedDescription,
                ingredients: [],
                steps: []
            )
        }
        
        isLoading = false
    }
    
    // MARK: - Persistence
    
    private func saveMeals() {
        if let data = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadMeals() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Meal].self, from: data) {
            meals = decoded
        }
    }
}

