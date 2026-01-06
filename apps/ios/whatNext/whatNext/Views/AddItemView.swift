//
//  AddItemView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct AddItemView: View {
    @State private var text: String = ""
    
    var body: some View {
        Form {
            Section("New Next") {
                TextField("Whats next?", text: $text)
                
                Button("Save") {
                    text = ""
                }
                .disabled(text.isEmpty)
            }
            .navigationTitle("Add")
        }
    }
}
