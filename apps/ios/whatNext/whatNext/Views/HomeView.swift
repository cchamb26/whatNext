//
//  HomeView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(MealStore.self) private var store
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("whatNext?")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    if APIService.shared.isAuthenticated {
                        Text("\(store.meals.count) meals logged")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Not connected", systemImage: "wifi.slash")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.top, 20)
                
                // Main recommendation button/card
                Button {
                    Task {
                        await store.getRecommendation()
                    }
                } label: {
                    recommendationCard
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
                
                // Error message
                if let error = store.errorMessage {
                    errorCard(message: error)
                }
                
                // Recipe details
                if let rec = store.recommendation, !rec.ingredients.isEmpty {
                    recipeCard(rec)
                }
                
                // Recent meals preview
                if !store.meals.isEmpty {
                    recentMealsSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Recommendation Card
    
    private var recommendationCard: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(height: 60)
                    Text("Getting recommendation...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else if let rec = store.recommendation {
                // Recommendation Section
                VStack(spacing: 12) {
                    Text("RECOMMENDATION")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .tracking(1)
                    
                    Text(rec.food)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                
                // Divider
                if !rec.reason.isEmpty {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    // Why Section
                    VStack(spacing: 8) {
                        Text("WHY")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        
                        Text(rec.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                    
                    Text("Tap to get a recommendation")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("Requires backend connection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 20)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Error Card
    
    private func errorCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Recipe Card
    
    private func recipeCard(_ rec: Recommendation) -> some View {
        VStack(spacing: 0) {
            // Ingredients Section
            VStack(alignment: .leading, spacing: 12) {
                Text("INGREDIENTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .tracking(1)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(rec.ingredients, id: \.self) { ingredient in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.orange.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(ingredient)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            
            // Divider
            if !rec.steps.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Steps Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("STEPS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .tracking(1)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(rec.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.orange.opacity(0.8))
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Recent Meals
    
    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Meals")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 1) {
                ForEach(store.meals.prefix(5)) { meal in
                    HStack {
                        Image(systemName: meal.mealEvent.icon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        
                        Text(meal.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(meal.timeString)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
