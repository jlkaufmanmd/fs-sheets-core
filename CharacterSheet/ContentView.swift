import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RPGCharacter.name) private var characters: [RPGCharacter]
    @Query private var libraries: [RulesLibrary]

    @State private var selectedCharacter: RPGCharacter?

    private var library: RulesLibrary {
        if let existing = libraries.first { return existing }
        let created = RulesLibrary()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCharacter) {
                ForEach(characters) { c in
                    Text(c.name).tag(c as RPGCharacter?)
                }
                .onDelete(perform: deleteCharacters)
            }
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addNewCharacterAndOpen()
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedCharacter {
                CharacterDetailView(character: selectedCharacter, library: library)
            } else {
                ContentUnavailableView("Select a character", systemImage: "person.text.rectangle")
            }
        }
        .onAppear {
            if selectedCharacter == nil, let first = characters.first {
                selectedCharacter = first
            }
        }
        .onChange(of: characters.count) { _, _ in
            if selectedCharacter == nil, let first = characters.first {
                selectedCharacter = first
            }
        }
    }

    private func addNewCharacterAndOpen() {
        let c = RPGCharacter(name: "New Character")
        modelContext.insert(c)
        selectedCharacter = c
    }

    private func deleteCharacters(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(characters[i])
        }
        if let selected = selectedCharacter, !characters.contains(where: { $0.persistentModelID == selected.persistentModelID }) {
            selectedCharacter = characters.first
        }
    }
}
