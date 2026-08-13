import SwiftUI

struct HabitRowView: View {
    let habit: Habit

    private var habitColor: Color {
        let hex = habit.colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return Color(red: 0.00, green: 0.45, blue: 0.30) }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if habit.iconName == "sparkles",
                   let customText = habit.customIconText,
                   !customText.isEmpty {
                    Text(customText)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Image(systemName: habit.iconName)
                        .font(.title2)
                }
            }
                .foregroundStyle(habitColor)
                .frame(width: 44, height: 44)
                .background(habitColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !habit.detail.isEmpty {
                    Text(habit.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Label(
                    habit.isActive ? "有効" : "お休み中",
                    systemImage: habit.isActive ? "checkmark.circle.fill" : "pause.circle.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(habit.isActive ? habitColor : .secondary)

                if let minutes = habit.plannedDurationMinutes {
                    Label("予定 \(minutes)分", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("ダブルタップするとカード一覧を開きます")
    }

    private var accessibilitySummary: String {
        let detail = habit.detail.isEmpty ? "" : "、\(habit.detail)"
        let status = habit.isActive ? "有効" : "お休み中"
        return "\(habit.title)\(detail)、\(status)"
    }
}
