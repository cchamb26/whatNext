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
        ZStack(alignment: .bottom) {
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
                    
                    // Error message
                    if let error = store.errorMessage {
                        errorCard(message: error)
                    }
                    
                    // Recommendation result (only shown after fetching)
                    if store.recommendation != nil || store.isLoading {
                        recommendationCard
                    }
                    
                    // Recipe details
                    if let rec = store.recommendation, !rec.ingredients.isEmpty {
                        recipeCard(rec)
                    }
                    
                    // Recent meals
                    if !store.meals.isEmpty {
                        recentMealsSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            
            // Persistent "what next?" button
            whatNextButton
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - What Next Button
    
    private var whatNextButton: some View {
        Button {
            Task {
                await store.getRecommendation()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                Text("what next?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .orange.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(store.isLoading || !APIService.shared.isAuthenticated)
        .opacity(store.isLoading ? 0.6 : 1)
        .padding(.bottom, 24)
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
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.caption)
                        Text("RECOMMENDATION")
                            .font(.caption)
                            .tracking(1)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    
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
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb")
                                .font(.caption)
                            Text("WHY")
                                .font(.caption)
                                .tracking(1)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        
                        Text(rec.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
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
                HStack(spacing: 6) {
                    Image(systemName: "basket")
                        .font(.caption)
                    Text("INGREDIENTS")
                        .font(.caption)
                        .tracking(1)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
                
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
                    HStack(spacing: 6) {
                        Image(systemName: "list.number")
                            .font(.caption)
                        Text("STEPS")
                            .font(.caption)
                            .tracking(1)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    
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
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                    Text("RECENT MEALS")
                        .font(.caption)
                        .tracking(1)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(store.meals.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(Array(store.meals.prefix(5).enumerated()), id: \.element.id) { index, meal in
                    mealRow(meal: meal, index: index)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func mealRow(meal: Meal, index: Int) -> some View {
        HStack {
            Image(systemName: meal.mealEvent.icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.subheadline)
                Text(meal.mealEvent.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Text(meal.timeString)
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            // Delete button
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.deleteMeal(at: IndexSet(integer: index))
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
    }
}
