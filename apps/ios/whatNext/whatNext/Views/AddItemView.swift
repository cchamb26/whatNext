//
//  AddItemView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct AddItemView: View {
    @Environment(MealStore.self) private var store
    
    @State private var name: String = ""
    @State private var mealEvent: MealEvent = .lunch
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var showingConfirmation = false
    @State private var isSaving = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Picker Card
                datePickerCard
                
                // Meals for selected date
                mealsForDateCard
                
                // Add Meal Form
                addMealFormCard
                
                // Error/Status messages
                if let error = store.errorMessage {
                    errorCard(message: error)
                }
                
                if !APIService.shared.isAuthenticated {
                    notConnectedCard
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Add Meal")
        .onAppear {
            Task {
                await store.fetchMeals(for: selectedDate)
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            Task {
                await store.fetchMeals(for: newDate)
            }
        }
        .overlay {
            if showingConfirmation {
                confirmationOverlay
            }
        }
    }
    
    // MARK: - Date Picker Card
    
    private var datePickerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("SELECT DATE")
                    .font(.caption)
                    .tracking(1)
            }
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.orange)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Meals for Date Card
    
    private var mealsForDateCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                    Text("MEALS FOR \(dateFormatter.string(from: selectedDate).uppercased())")
                        .font(.caption)
                        .tracking(1)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                if store.isLoadingDateMeals {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(store.mealsForSelectedDate.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
            
            if store.mealsForSelectedDate.isEmpty && !store.isLoadingDateMeals {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No meals logged")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 1) {
                    ForEach(store.mealsForSelectedDate) { meal in
                        mealRow(meal: meal)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    private func mealRow(meal: Meal) -> some View {
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
            
            Text(timeFormatter.string(from: meal.occurredAt))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.deleteMealForDate(meal)
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
        .background(Color(.systemGray6))
    }
    
    // MARK: - Add Meal Form Card
    
    private var addMealFormCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.caption)
                Text("ADD NEW MEAL")
                    .font(.caption)
                    .tracking(1)
            }
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Food name
            VStack(alignment: .leading, spacing: 6) {
                Text("What did you eat?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g., Chicken salad", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Meal type
            VStack(alignment: .leading, spacing: 6) {
                Text("Meal type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Type", selection: $mealEvent) {
                    ForEach(MealEvent.allCases, id: \.self) { event in
                        Text(event.rawValue).tag(event)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Time picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Time eaten")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Save button
            Button {
                Task { await saveMeal() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text("Save Meal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving
                              ? Color.gray
                              : Color.orange)
                )
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Status Cards
    
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
    
    private var notConnectedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Not connected to backend")
                    .font(.subheadline)
                Text("Meals will be saved locally only")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var confirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Saved!")
                .font(.headline)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Save
    
    private func saveMeal() async {
        // Combine selected date with selected time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        let occurredAt = calendar.date(from: combined) ?? Date()
        
        let meal = Meal(
            name: name.trimmingCharacters(in: .whitespaces),
            hour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            mealEvent: mealEvent,
            occurredAt: occurredAt
        )
        
        isSaving = true
        await store.addMeal(meal)
        isSaving = false
        
        // Show confirmation
        withAnimation(.spring(duration: 0.3)) {
            showingConfirmation = true
        }
        
        // Reset form (keep date, reset other fields)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation {
            showingConfirmation = false
        }
        name = ""
        selectedTime = Date()
    }
}
