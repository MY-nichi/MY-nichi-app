import SwiftUI

struct HabitRowView: View {
    let habit: Habit

    private let emerald = Color(red: 0.00, green: 0.45, blue: 0.30)

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundStyle(emerald)
                .frame(width: 44, height: 44)
                .background(emerald.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(habit.isActive ? emerald : .secondary)
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
