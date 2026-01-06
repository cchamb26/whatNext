//
//  HomeView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Get Recommendation").font(.title).bold()
        }
        
        .padding()
        .navigationTitle("Home")
    }
}
