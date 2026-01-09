//
//  APIService.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

class APIService {
    static let shared = APIService()
    
    // Configure your backend URL here
    var baseURL: String {
        get { UserDefaults.standard.string(forKey: "baseURL") ?? "https://whatnext-api.azuremicrosoft.net" }
        set { UserDefaults.standard.set(newValue, forKey: "baseURL") }
    }
    
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }
    
    var isAuthenticated: Bool { authToken != nil && !authToken!.isEmpty }
    
    private init() {}
    
    // MARK: - Meals
    
    func fetchMeals() async throws -> [Meal] {
        let data = try await request(endpoint: "/meals/latest", method: "GET")
        let response = try JSONDecoder().decode(MealsResponse.self, from: data)
        return response.meals.map { $0.toMeal() }
    }
    
    func fetchMeals(for date: Date) async throws -> [Meal] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let dateString = formatter.string(from: date)
        
        let data = try await request(endpoint: "/meals?date=\(dateString)", method: "GET")
        let response = try JSONDecoder().decode(MealsForDateResponse.self, from: data)
        return response.meals.map { $0.toMeal() }
    }
    
    func addMeal(_ meal: Meal) async throws -> Meal {
        let body = MealRequest(
            name: meal.name,
            meal_event: meal.mealEvent.rawValue,
            occurred_at: ISO8601DateFormatter().string(from: meal.occurredAt)
        )
        
        let data = try await request(endpoint: "/meals", method: "POST", body: body)
        let response = try JSONDecoder().decode(MealResponse.self, from: data)
        return response.meal.toMeal()
    }
    
    func deleteMeal(id: String) async throws {
        _ = try await request(endpoint: "/meals/\(id)", method: "DELETE")
    }
    
    // MARK: - Recommendation
    
    func fetchRecommendation() async throws -> Recommendation {
        let data = try await request(endpoint: "/recommend", method: "POST")
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: data)
        return parseRecommendation(from: response.recommendation)
    }
    
    // MARK: - Network Layer
    
    private func request(endpoint: String, method: String, body: Encodable? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    // MARK: - Parse AI Response
    
    private func parseRecommendation(from text: String) -> Recommendation {
        // Try to parse as JSON
        if let data = text.data(using: .utf8),
           let json = try? JSONDecoder().decode(RecommendationJSON.self, from: data) {
            return Recommendation(
                food: json.food,
                reason: json.reason,
                ingredients: json.ingredients,
                steps: json.steps
            )
        }
        
        // Fallback if JSON parsing fails
        return Recommendation(food: text, reason: "", ingredients: [], steps: [])
    }
}

// JSON structure for AI recommendation response
struct RecommendationJSON: Codable {
    let food: String
    let reason: String
    let ingredients: [String]
    let steps: [String]
}

// MARK: - API Models

struct MealsResponse: Codable {
    let user_id: String
    let meals: [APIMeal]
}

struct MealsForDateResponse: Codable {
    let date: String
    let user_id: String
    let meals: [APIMeal]
}

struct MealResponse: Codable {
    let meal: APIMeal
}

struct APIMeal: Codable {
    let id: String
    let name: String
    let hour: Int
    let minute: Int
    let meal_event: String
    let occurred_at: String
    
    func toMeal() -> Meal {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: occurred_at) ?? Date()
        
        return Meal(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            hour: hour,
            minute: minute,
            mealEvent: MealEvent(rawValue: meal_event) ?? .snack,
            occurredAt: date
        )
    }
}

struct MealRequest: Codable {
    let name: String
    let meal_event: String
    let occurred_at: String
}

struct RecommendationResponse: Codable {
    let recommendation: String
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Invalid or expired token"
        case .serverError(let message): return message
        case .networkError(let message): return "Network error: \(message)"
        }
    }
}
