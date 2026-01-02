//
//  StatEditView.swift
//  CharacterSheet
//
//  Created by Jacob Kaufman on 12/30/25.
//

import SwiftUI
import SwiftData

struct StatEditView: View {
    @Bindable var stat: Stat
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Form {
            Section("Stat Name") {
                Text(stat.name)
                    .font(.headline)
            }
            
            Section {
                VStack(spacing: 20) {
                    // Current value display
                    Text("\(stat.value)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Direct numeric entry
                    TextField("Enter value", value: $stat.value, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .focused($isTextFieldFocused)
                        .onChange(of: stat.value) { _, _ in
                            enforceMinimum()
                        }
                    
                    // +/- buttons as alternative
                    HStack(spacing: 30) {
                        Button {
                            stat.value -= 1
                            enforceMinimum()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            stat.value += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical)
            } header: {
                Text("Value (minimum: \(stat.minimumValue))")
            }
        }
        .navigationTitle("Edit \(stat.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
            }
        }
        .onAppear {
            // Ensure value is valid when opening
            enforceMinimum()
        }
    }
    
    private func enforceMinimum() {
        if stat.value < stat.minimumValue {
            stat.value = stat.minimumValue
        }
    }
}

