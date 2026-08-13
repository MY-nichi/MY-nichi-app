import SwiftUI

struct AchievementStampView: View {
    let achievement: TaskAchievement
    var isSelected = false
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 2 : 8) {
            ZStack {
                Circle().fill(achievement.color.opacity(0.14))
                Circle().stroke(achievement.color, lineWidth: isSelected ? 4 : 2)
                Text(achievement.mark)
                    .font(compact ? .title3.bold() : .system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(achievement.color)
                if achievement == .excellent && !compact {
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(achievement.color)
                        .offset(x: 27, y: -25)
                }
            }
            .frame(width: compact ? 36 : 76, height: compact ? 36 : 76)

            if !compact {
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(achievement.color)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.mark)、\(achievement.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AchievementPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cardTitle: String
    let selectedAchievement: TaskAchievement?
    let onSelect: (TaskAchievement?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text(cardTitle).font(.title2.bold())
                    Text("今日はどのくらいできましたか？")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                HStack(alignment: .top, spacing: 18) {
                    ForEach(TaskAchievement.allCases) { achievement in
                        Button {
                            onSelect(achievement)
                            dismiss()
                        } label: {
                            AchievementStampView(
                                achievement: achievement,
                                isSelected: selectedAchievement == achievement
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedAchievement != nil {
                    Button("未完了に戻す", role: .destructive) {
                        onSelect(nil)
                        dismiss()
                    }
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("できばえスタンプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(330)])
    }
}
