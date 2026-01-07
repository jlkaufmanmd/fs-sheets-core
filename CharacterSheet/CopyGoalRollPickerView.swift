import SwiftUI
import SwiftData

struct CopyGoalRollPickerView: View {
    @Binding var isPresented: Bool
    let categories: [GoalRollCategory]
    let onSelect: (GoalRollCategory) -> Void
    let onCreateNew: (String) -> Void

    @State private var showingNewCategoryAlert = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        showingNewCategoryAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("New Category")
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Section {
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
            }
            .navigationTitle("Copy to Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("New Category", isPresented: $showingNewCategoryAlert) {
                TextField("Category Name", text: $newCategoryName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Create") {
                    onCreateNew(newCategoryName)
                    newCategoryName = ""
                    isPresented = false
                }
            } message: {
                Text("Enter a name for the new category")
            }
        }
    }
}
