//
//  MealStore.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

@Observable
class MealStore {
    var meals: [Meal] = []
    var mealsForSelectedDate: [Meal] = []
    var selectedDate: Date = Date()
    var recommendation: Recommendation?
    var isLoading: Bool = false
    var isSyncing: Bool = false
    var isLoadingDateMeals: Bool = false
    var errorMessage: String?
    
    private let storageKey = "savedMeals"
    private let api = APIService.shared
    
    init() {
        loadLocalMeals()
    }
    
    // MARK: - Meals
    
    func addMeal(_ meal: Meal) async {
        // Add locally for instant feedback
        meals.insert(meal, at: 0)
        saveLocalMeals()
        
        // Also add to date-filtered list if same date
        if Calendar.current.isDate(meal.occurredAt, inSameDayAs: selectedDate) {
            mealsForSelectedDate.append(meal)
            mealsForSelectedDate.sort { $0.occurredAt < $1.occurredAt }
        }
        
        // Sync to backend
        guard api.isAuthenticated else {
            errorMessage = "Not authenticated - meal saved locally only"
            return
        }
        
        do {
            _ = try await api.addMeal(meal)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to sync: \(error.localizedDescription)"
        }
    }
    
    func deleteMeal(at offsets: IndexSet) {
        let mealsToDelete = offsets.map { meals[$0] }
        meals.remove(atOffsets: offsets)
        saveLocalMeals()
        
        guard api.isAuthenticated else { return }
        
        Task {
            for meal in mealsToDelete {
                try? await api.deleteMeal(id: meal.id.uuidString)
            }
        }
    }
    
    func deleteMealForDate(_ meal: Meal) {
        mealsForSelectedDate.removeAll { $0.id == meal.id }
        meals.removeAll { $0.id == meal.id }
        saveLocalMeals()
        
        guard api.isAuthenticated else { return }
        
        Task {
            try? await api.deleteMeal(id: meal.id.uuidString)
        }
    }
    
    func syncMeals() async {
        guard api.isAuthenticated else {
            errorMessage = "Not authenticated"
            return
        }
        
        isSyncing = true
        errorMessage = nil
        
        do {
            let remoteMeals = try await api.fetchMeals()
            meals = remoteMeals
            saveLocalMeals()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func fetchMeals(for date: Date) async {
        selectedDate = date
        
        guard api.isAuthenticated else {
            // Filter local meals for the selected date
            mealsForSelectedDate = meals.filter {
                Calendar.current.isDate($0.occurredAt, inSameDayAs: date)
            }.sorted { $0.occurredAt < $1.occurredAt }
            return
        }
        
        isLoadingDateMeals = true
        errorMessage = nil
        
        do {
            mealsForSelectedDate = try await api.fetchMeals(for: date)
        } catch {
            errorMessage = error.localizedDescription
            // Fallback to local
            mealsForSelectedDate = meals.filter {
                Calendar.current.isDate($0.occurredAt, inSameDayAs: date)
            }.sorted { $0.occurredAt < $1.occurredAt }
        }
        
        isLoadingDateMeals = false
    }
    
    // MARK: - Recommendation
    
    func getRecommendation() async {
        guard api.isAuthenticated else {
            errorMessage = "Not authenticated - add your token in Settings"
            recommendation = nil
            return
        }
        
        guard !meals.isEmpty else {
            errorMessage = "Add some meals first"
            recommendation = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        recommendation = nil
        
        do {
            recommendation = try await api.fetchRecommendation()
        } catch {
            errorMessage = error.localizedDescription
            recommendation = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Local Storage
    
    private func saveLocalMeals() {
        if let data = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadLocalMeals() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Meal].self, from: data) {
            meals = decoded
        }
    }
}
