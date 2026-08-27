import SwiftUI

struct AchievementStampView: View {
    let achievement: TaskAchievement
    var isSelected = false
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 2 : 8) {
            AchievementFaceIcon(achievement: achievement, isSelected: isSelected, compact: compact)

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

struct AchievementFaceIcon: View {
    let achievement: TaskAchievement
    var isSelected = false
    var compact = false
    var size: CGFloat?

    private var iconSize: CGFloat {
        size ?? (compact ? 36 : 76)
    }

    private var fillColor: Color {
        switch achievement {
        case .excellent: Color(red: 1.00, green: 0.86, blue: 0.91)
        case .needsPractice: Color(red: 1.00, green: 0.94, blue: 0.76)
        case .achieved: Color(red: 0.82, green: 0.96, blue: 0.89)
        case .rest: Color(red: 0.90, green: 0.91, blue: 1.00)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
            Circle()
                .stroke(achievement.color, lineWidth: isSelected ? max(2, iconSize * 0.052) : max(1.5, iconSize * 0.026))

            face

            if achievement == .excellent && !compact {
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize * 0.18, weight: .bold))
                    .foregroundStyle(achievement.color)
                    .offset(x: iconSize * 0.36, y: -iconSize * 0.33)
            }
        }
        .frame(width: iconSize, height: iconSize)
    }

    private var face: some View {
        ZStack {
            eyes
            if achievement == .rest {
                Text("Zz")
                    .font(.system(size: iconSize * 0.2, weight: .bold, design: .rounded))
                    .foregroundStyle(achievement.color)
                    .offset(x: iconSize * 0.18, y: -iconSize * 0.18)
            } else {
                AchievementMouthShape(achievement: achievement)
                    .stroke(achievement.color, style: StrokeStyle(lineWidth: max(1.4, iconSize * 0.036), lineCap: .round))
                    .frame(width: iconSize * 0.42, height: iconSize * 0.22)
                    .offset(y: iconSize * 0.12)
            }
        }
    }

    private var brows: some View {
        HStack(spacing: iconSize * 0.12) {
            brow
            brow.scaleEffect(x: -1)
        }
        .offset(y: -iconSize * 0.22)
    }

    private var brow: some View {
        AchievementBrowShape(achievement: achievement)
            .stroke(achievement.color, style: StrokeStyle(lineWidth: max(1.2, iconSize * 0.03), lineCap: .round))
            .frame(width: iconSize * 0.16, height: iconSize * 0.08)
    }

    private var eyes: some View {
        HStack(spacing: iconSize * 0.18) {
            eye
            eye
        }
        .offset(y: achievement == .rest ? -iconSize * 0.02 : -iconSize * 0.1)
    }

    private var eye: some View {
        Group {
            if achievement == .rest {
                AchievementRestEyeShape()
                    .stroke(achievement.color, style: StrokeStyle(lineWidth: max(1.4, iconSize * 0.034), lineCap: .round))
                    .frame(width: iconSize * 0.14, height: iconSize * 0.07)
            } else if achievement == .excellent || achievement == .needsPractice || achievement == .achieved {
                AchievementHappyEyeShape()
                    .stroke(achievement.color, style: StrokeStyle(lineWidth: max(1.4, iconSize * 0.034), lineCap: .round))
                    .frame(width: iconSize * 0.13, height: iconSize * 0.08)
            } else {
                Circle()
                    .fill(achievement.color)
                    .frame(width: iconSize * 0.075, height: iconSize * 0.075)
            }
        }
    }
}

private struct AchievementRestEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct AchievementHappyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

private struct AchievementBrowShape: Shape {
    let achievement: TaskAchievement

    func path(in rect: CGRect) -> Path {
        Path()
    }
}

private struct AchievementMouthShape: Shape {
    let achievement: TaskAchievement

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch achievement {
        case .excellent:
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.midY - rect.height * 0.18))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.midY - rect.height * 0.18),
                control: CGPoint(x: rect.midX, y: rect.maxY * 1.28)
            )
        case .needsPractice:
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.maxY * 0.78)
            )
        case .achieved:
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.maxY * 0.72)
            )
        case .rest:
            break
        }
        return path
    }
}

struct AchievementPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cardTitle: String
    let selectedAchievement: TaskAchievement?
    let memo: String
    var showsNavigationTitle = true
    let onSelect: (TaskAchievement?, String) -> Void
    @State private var note: String
    @State private var pendingAchievement: TaskAchievement?

    init(
        cardTitle: String,
        selectedAchievement: TaskAchievement?,
        memo: String = "",
        showsNavigationTitle: Bool = true,
        onSelect: @escaping (TaskAchievement?, String) -> Void
    ) {
        self.cardTitle = cardTitle
        self.selectedAchievement = selectedAchievement
        self.memo = memo
        self.showsNavigationTitle = showsNavigationTitle
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
            .navigationTitle(showsNavigationTitle ? "できばえスタンプ" : "")
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
