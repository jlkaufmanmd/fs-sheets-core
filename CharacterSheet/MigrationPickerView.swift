import SwiftUI
import SwiftData

struct MigrationPickerView: View {
    @Binding var isPresented: Bool
    let categories: [GoalRollCategory]
    let onSelect: (GoalRollCategory) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                        isPresented = false
                    } label: {
                        HStack {
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Move Rolls To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
