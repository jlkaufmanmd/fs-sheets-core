//
//  ContentView.swift
//  CharacterSheet
//
//  Created by Jacob Kaufman on 12/30/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RPGCharacter.name) private var characters: [RPGCharacter]
    @Query private var libraries: [RulesLibrary]

    var body: some View {
        NavigationStack {
            List {
                Section("Characters") {
                    if characters.isEmpty {
                        Text("No characters yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(characters) { c in
                            NavigationLink(c.name) {
                                CharacterDetailView(character: c)
                            }
                        }
                        .onDelete(perform: deleteCharacters)
                    }
                }
            }
            .navigationTitle("Character Sheets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createCharacter()
                    } label: {
                        Label("Add Character", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                ensureLibraryExists()
            }
        }
    }

    private func ensureLibraryExists() {
        if libraries.isEmpty {
            modelContext.insert(RulesLibrary())
        }
    }

    private func createCharacter() {
        ensureLibraryExists()

        let newCharacter = RPGCharacter(name: "My Hero")

        // ---- ATTRIBUTES ----
        var order = 0
        func addAttr(_ name: String, _ category: String, _ value: Int) {
            newCharacter.stats.append(
                Stat(name: name, value: value, statType: "attribute", category: category, displayOrder: order, isDeletable: false)
            )
            order += 1
        }

        addAttr("Strength", "Body", 3)
        addAttr("Dexterity", "Body", 3)
        addAttr("Endurance", "Body", 3)

        addAttr("Wits", "Mind", 3)
        addAttr("Perception", "Mind", 3)
        addAttr("Tech", "Mind", 3)

        addAttr("Passion", "Spirit", 3)
        addAttr("Calm", "Spirit", 3)
        addAttr("Introvert", "Spirit", 3)
        addAttr("Extrovert", "Spirit", 3)
        addAttr("Faith", "Spirit", 3)
        addAttr("Ego", "Spirit", 3)

        addAttr("Psi", "Occult", 0)
        addAttr("Theurgy", "Occult", 0)

        // ---- NATURAL SKILLS ----
        order = 0
        func addNat(_ name: String, _ value: Int) {
            newCharacter.stats.append(
                Stat(name: name, value: value, statType: "skill", category: "Natural Skills", displayOrder: order, isDeletable: false)
            )
            order += 1
        }

        addNat("Charm", 1)
        addNat("Dodge", 1)
        addNat("Fight", 1)
        addNat("Impress", 1)
        addNat("Melee", 1)
        addNat("Observe", 1)
        addNat("Shoot", 1)
        addNat("Sneak", 1)
        addNat("Vigor", 1)

        modelContext.insert(newCharacter)
    }

    private func deleteCharacters(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(characters[i])
        }
    }
}
