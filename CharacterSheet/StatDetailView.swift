import SwiftUI
import SwiftData

struct StatDetailView: View {
    @Bindable var stat: Stat

    var body: some View {
        Form {
            Section("Name") {
                Text(stat.name)
            }

            Section("Category") {
                Text(stat.category)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Base Value")
                    Spacer()
                    Text("\(stat.value)")
                        .font(.headline)
                }

                // Show effective value and modifiers breakdown here
                // TODO: Add modifier calculation and display
                HStack {
                    Text("Effective Value")
                    Spacer()
                    Text("\(stat.value)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("All Keywords") {
                Text(stat.implicitKeywords.joined(separator: ", "))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Stat Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
