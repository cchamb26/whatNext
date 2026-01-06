//
//  HomeView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color("HomeViewBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Button("Get Recommendation") {
                    //do something
                }
            }
            .padding()
        }

        .navigationTitle("Home")
    }
    
}
