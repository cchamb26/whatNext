//
//  AddItemView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct AddItemView: View {
    @Environment(MealStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var mealEvent: MealEvent = .lunch
    @State private var time: Date = Date()
    @State private var showingConfirmation = false
    
    var body: some View {
        Form {
            Section {
                TextField("What did you eat?", text: $name)
                    .font(.body)
            } header: {
                Text("Meal")
            }
            
            Section {
                Picker("Type", selection: $mealEvent) {
                    ForEach(MealEvent.allCases, id: \.self) { event in
                        Label(event.rawValue.capitalized, systemImage: event.icon)
                            .tag(event)
                    }
                }
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
            } header: {
                Text("Details")
            }
            
            Section {
                Button {
                    saveMeal()
                } label: {
                    HStack {
                        Spacer()
                        Text("Save Meal")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Add Meal")
        .overlay {
            if showingConfirmation {
                confirmationOverlay
            }
        }
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
    
    private func saveMeal() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        let meal = Meal(
            name: name.trimmingCharacters(in: .whitespaces),
            hour: hour,
            minute: minute,
            mealEvent: mealEvent,
            occurredAt: time
        )
        
        store.addMeal(meal)
        
        // Show confirmation
        withAnimation(.spring(duration: 0.3)) {
            showingConfirmation = true
        }
        
        // Reset form
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showingConfirmation = false
            }
            name = ""
            time = Date()
        }
    }
}
