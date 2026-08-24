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
    let memo: String
    let onSelect: (TaskAchievement?, String) -> Void
    @State private var note: String
    @State private var pendingAchievement: TaskAchievement?

    init(
        cardTitle: String,
        selectedAchievement: TaskAchievement?,
        memo: String = "",
        onSelect: @escaping (TaskAchievement?, String) -> Void
    ) {
        self.cardTitle = cardTitle
        self.selectedAchievement = selectedAchievement
        self.memo = memo
        self.onSelect = onSelect
        _note = State(initialValue: memo)
        _pendingAchievement = State(initialValue: selectedAchievement)
    }

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
                            pendingAchievement = achievement
                        } label: {
                            AchievementStampView(
                                achievement: achievement,
                                isSelected: pendingAchievement == achievement
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("今日のひとこと")
                        .font(.subheadline.bold())
                    TextField("任意で短く残す", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 80 {
                                note = String(newValue.prefix(80))
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if selectedAchievement != nil {
                    Button("未完了に戻す", role: .destructive) {
                        onSelect(nil, "")
                        dismiss()
                    }
                }

                Button {
                    saveSelection()
                } label: {
                    Text("保存")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pendingAchievement == nil)

                Spacer()
            }
            .padding(24)
            .navigationTitle("できばえスタンプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSelection()
                    }
                    .fontWeight(.semibold)
                    .disabled(pendingAchievement == nil)
                }
            }
        }
        .presentationDetents([.height(430)])
    }

    private func saveSelection() {
        guard let pendingAchievement else { return }
        onSelect(pendingAchievement, note)
        dismiss()
    }
}
