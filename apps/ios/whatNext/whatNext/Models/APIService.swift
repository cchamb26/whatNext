//
//  APIService.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    // Configure your backend URL here
    var baseURL: String {
        get { UserDefaults.standard.string(forKey: "baseURL") ?? "http://localhost:3000" }
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
    
    func addMeal(_ meal: Meal) async throws -> Meal {
        let body = MealRequest(
            name: meal.name,
            hour: meal.hour,
            minute: meal.minute,
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
        var food = ""
        var reason = ""
        var ingredients: [String] = []
        var steps: [String] = []
        
        let lines = text.components(separatedBy: "\n")
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.lowercased().hasPrefix("recommendation:") {
                currentSection = "food"
                let value = trimmed.dropFirst("recommendation:".count).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { food = value }
            } else if trimmed.lowercased().hasPrefix("why:") {
                currentSection = "reason"
                let value = trimmed.dropFirst("why:".count).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { reason = value }
            } else if trimmed.lowercased().contains("ingredients:") {
                currentSection = "ingredients"
                let value = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    ingredients = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                }
            } else if trimmed.lowercased().contains("steps:") {
                currentSection = "steps"
                let value = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { steps.append(value) }
            } else if !trimmed.isEmpty {
                switch currentSection {
                case "food": food = trimmed
                case "reason": reason += (reason.isEmpty ? "" : " ") + trimmed
                case "steps":
                    let step = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "- •0123456789."))
                        .trimmingCharacters(in: .whitespaces)
                    if !step.isEmpty { steps.append(step) }
                default: break
                }
            }
        }
        
        return Recommendation(
            food: food.isEmpty ? text : food,
            reason: reason,
            ingredients: ingredients,
            steps: steps
        )
    }
}

// MARK: - API Models

struct MealsResponse: Codable {
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
    let hour: Int
    let minute: Int
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
