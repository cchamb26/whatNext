//
//  SettingsView.swift
//  whatNext
//
//  Created by Jack on 1/6/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(MealStore.self) private var store
    @State private var token: String = ""
    @State private var serverURL: String = ""
    @State private var showingToken = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    if APIService.shared.isAuthenticated {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not connected", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Section {
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { saveURL() }
            } header: {
                Text("Backend")
            } footer: {
                Text("Default: http://localhost:3000")
            }
            
            Section {
                HStack {
                    if showingToken {
                        TextField("Paste JWT token", text: $token)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("Paste JWT token", text: $token)
                    }
                    
                    Button {
                        showingToken.toggle()
                    } label: {
                        Image(systemName: showingToken ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button("Save Token") {
                    APIService.shared.authToken = token.isEmpty ? nil : token
                }
                .disabled(token.isEmpty)
                
                if APIService.shared.isAuthenticated {
                    Button("Clear Token", role: .destructive) {
                        APIService.shared.authToken = nil
                        token = ""
                    }
                }
            } header: {
                Text("Authentication")
            } footer: {
                Text("Enter your Supabase JWT to connect to the backend.")
            }
            
            Section {
                Button {
                    Task { await store.syncMeals() }
                } label: {
                    HStack {
                        Text("Sync Meals from Server")
                        Spacer()
                        if store.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(!APIService.shared.isAuthenticated || store.isSyncing)
            }
            
            Section {
                HStack {
                    Text("Meals Logged")
                    Spacer()
                    Text("\(store.meals.count)")
                        .foregroundStyle(.secondary)
                }
                
                if !store.meals.isEmpty {
                    Button("Clear All Local Meals", role: .destructive) {
                        store.meals.removeAll()
                        UserDefaults.standard.removeObject(forKey: "savedMeals")
                    }
                }
            } header: {
                Text("Local Data")
            }
            
            if let error = store.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                } header: {
                    Text("Last Error")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            token = APIService.shared.authToken ?? ""
            serverURL = APIService.shared.baseURL
        }
    }
    
    private func saveURL() {
        if !serverURL.isEmpty {
            APIService.shared.baseURL = serverURL
        }
    }
}
