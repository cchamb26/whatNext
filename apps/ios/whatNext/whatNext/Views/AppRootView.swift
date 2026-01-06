//
//  AppRootView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct AppRootView: View {
    @State private var store = MealStore()
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }
            
            NavigationStack {
                AddItemView()
            }
            .tabItem { Label("Add", systemImage: "plus") }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.orange)
        .environment(store)
    }
}
