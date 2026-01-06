//
//  AppRootView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {Label("Home", systemImage: "house")}
            
            NavigationStack {
                AddItemView()
            }
            .tabItem {Label("Add", systemImage: "plus")}
        }
    }
}
