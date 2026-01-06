//
//  HomeView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(MealStore.self) private var store
    @State private var hasRequested = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("what next?")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("\(store.meals.count) meals logged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Main recommendation button/card
                Button {
                    hasRequested = true
                    Task {
                        await store.getRecommendation()
                    }
                } label: {
                    recommendationCard
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
                
                // Recipe details (shown after request)
                if hasRequested && !store.recommendation.ingredients.isEmpty {
                    recipeCard
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
        VStack(spacing: 16) {
            if store.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(height: 60)
            } else {
                Image(systemName: hasRequested ? "fork.knife" : "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                
                Text(store.recommendation.food)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                if !store.recommendation.reason.isEmpty {
                    Text(store.recommendation.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Recipe Card
    
    private var recipeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Simple Recipe")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Ingredients", systemImage: "list.bullet")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                
                Text(store.recommendation.ingredients.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Steps", systemImage: "checklist")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                
                ForEach(Array(store.recommendation.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundStyle(.tertiary)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
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
