import SwiftUI
import SwiftData

/// A reusable cell for displaying and editing a Stat (attribute or natural skill)
/// Supports both vertical (attributes) and horizontal (natural skills) layouts
struct StatCell: View {
    @Bindable var stat: Stat
    @Binding var isExpanded: Bool
    var layout: Layout = .vertical

    enum Layout {
        case vertical   // Name above value (for attributes)
        case horizontal // Name left, value right (for natural skills)
    }

    var body: some View {
        VStack(spacing: 4) {
            // The stat cell itself
            Group {
                if layout == .vertical {
                    verticalLayout
                } else {
                    horizontalLayout
                }
            }
            .padding(layout == .vertical ? .vertical : .all, layout == .vertical ? 4 : 2)
            .padding(.horizontal, layout == .horizontal ? 4 : 0)
            .background(isExpanded ? Color(.systemGray6) : Color.clear)
            .cornerRadius(6)

            // Details appear directly below this stat
            if isExpanded {
                detailsView
            }
        }
        .frame(maxWidth: layout == .vertical ? .infinity : nil, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Layout Variants

    private var verticalLayout: some View {
        VStack(spacing: 2) {
            Text(stat.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .onTapGesture {
                    isExpanded.toggle()
                }

            valueControls
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: 4) {
            Text(stat.name)
                .font(.caption)
                .onTapGesture {
                    isExpanded.toggle()
                }
            Spacer()
            valueControls
        }
    }

    // MARK: - Shared Components

    private var valueControls: some View {
        HStack(spacing: 3) {
            Button {
                stat.value -= 1
                if stat.value < stat.minimumValue { stat.value = stat.minimumValue }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption2)
            }
            .buttonStyle(.plain)

            // Show "base (effective)" format when they differ
            if stat.hasModifiers && stat.value != stat.effectiveValue {
                Text("\(stat.value) (\(stat.effectiveValue))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(minWidth: layout == .vertical ? 18 : 20)
            } else {
                Text("\(stat.value)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(minWidth: layout == .vertical ? 18 : 20)
            }

            Button {
                stat.value += 1
            } label: {
                Image(systemName: "plus.circle")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Base")
                    .font(.caption2)
                Spacer()
                Text("\(stat.value)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }

            if stat.hasModifiers {
                HStack {
                    Text("Effective")
                        .font(.caption2)
                    Spacer()
                    Text("\(stat.effectiveValue)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                Text("Keywords")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(stat.implicitKeywords.joined(separator: ", "))
                    .font(.caption2)
                    .lineLimit(nil)
            }
        }
        .padding(6)
        .background(Color(.systemGray6))
        .cornerRadius(4)
    }
}
