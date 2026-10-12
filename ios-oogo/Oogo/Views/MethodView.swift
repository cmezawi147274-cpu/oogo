//
//  MethodView.swift
//  Oogo
//
//  The oogo method: how week work, day types, schedule, progression.
//

import SwiftUI

struct MethodView: View {
    let onBell: () -> Void

    @Environment(OogoStore.self) private var store

    private let paragraphs: [String] = [
        "body know five move: push, pull, legs, swing, middle. oogo train move, not body part.",
        "hunt day = push + legs. gather day = pull + swing + middle. carry and twist live in middle. swing hold all power work.",
        "hunt and gather take turns on work day. rotation walk straight through rest day. never reset on monday. feast mean rest.",
        "one move per slot. repeat for rounds. change one thing at a time."
    ]

    private let progression: [String] = [
        "move cleaner",
        "move slower",
        "more rep",
        "heavier bell",
        "harder move"
    ]

    var body: some View {
        VStack(spacing: 0) {
            OogoTopBar(onBell: onBell)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ScreenTitle(text: "oogo way", size: 34, showsRedDot: true)
                        .padding(.top, 12)

                    Text("train move, not muscle.")
                        .font(OogoFont.bodyStrong)
                        .foregroundStyle(OogoColor.ink)
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, text in
                            Text(text)
                                .font(OogoFont.subtitle)
                                .foregroundStyle(OogoColor.secondaryText)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 14)

                    SectionHeading(text: "three kind of day")
                        .padding(.top, 30)
                        .padding(.bottom, 12)

                    VStack(spacing: 11) {
                        dayRow(.hunt)
                        dayRow(.gather)
                        dayRow(.feast)
                    }

                    SectionHeading(text: "how week go")
                        .padding(.top, 30)
                        .padding(.bottom, 12)

                    VStack(spacing: 11) {
                        ForEach([3, 4, 5], id: \.self) { plan in
                            scheduleCard(plan)
                        }
                    }

                    SectionHeading(text: "how hooman grow")
                        .padding(.top, 30)
                        .padding(.bottom, 12)

                    progressionCard
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, OogoMetric.navClearance)
            }
        }
        .background(OogoColor.page)
    }

    // MARK: - Day types

    private func dayRow(_ day: DayType) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(barColor(day))
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(day.title.lowercased())
                    .font(OogoFont.bold(19))
                    .foregroundStyle(OogoColor.ink)
                Text(day.caveLine)
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard(radius: OogoRadius.smallCard)
    }

    private func barColor(_ day: DayType) -> Color {
        switch day {
        case .hunt: return OogoColor.ink
        case .gather: return OogoColor.red
        case .feast: return OogoColor.mist
        }
    }

    // MARK: - Schedule

    private func scheduleCard(_ plan: Int) -> some View {
        let weekA = weekTypes(plan: plan, week: 0)
        let weekB = weekTypes(plan: plan, week: 1)
        let isActive = store.daysPerWeek == plan

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\(plan) day week")
                    .font(OogoFont.bold(17))
                    .foregroundStyle(OogoColor.ink)
                Spacer(minLength: 0)
                if isActive {
                    HStack(spacing: 6) {
                        RedDot(size: 5)
                        Text("hooman plan")
                            .font(OogoFont.medium(13.5))
                            .foregroundStyle(OogoColor.secondaryText)
                    }
                }
            }

            HStack(spacing: 5) {
                ForEach(Array(weekdayInitials.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(OogoFont.medium(12.5))
                        .foregroundStyle(OogoColor.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            weekRow(weekA)
            if weekA != weekB {
                weekRow(weekB)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard(radius: OogoRadius.smallCard)
    }

    private var weekdayInitials: [String] { ["M", "T", "W", "T", "F", "S", "S"] }

    private func weekTypes(plan: Int, week: Int) -> [DayType] {
        let offsets = OogoStore.trainingOffsets(plan)
        return (0..<7).map { offset in
            guard let slot = offsets.firstIndex(of: offset) else { return .feast }
            let index = week * offsets.count + slot
            return index % 2 == 0 ? .hunt : .gather
        }
    }

    private func weekRow(_ types: [DayType]) -> some View {
        HStack(spacing: 5) {
            ForEach(Array(types.enumerated()), id: \.offset) { _, type in
                Group {
                    if type == .feast {
                        Circle()
                            .fill(OogoColor.secondaryText.opacity(0.45))
                            .frame(width: 4, height: 4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background { Capsule().fill(OogoColor.cloud) }
                    } else {
                        Text(type.shortName)
                            .font(OogoFont.semibold(11.5))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background {
                                Capsule().fill(type == .hunt ? OogoColor.ink : OogoColor.red)
                            }
                    }
                }
            }
        }
    }

    // MARK: - Progression

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("change one thing only. never two.")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(Array(progression.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 12) {
                        RedDot(size: 5)
                        Text(item)
                            .font(OogoFont.body)
                            .foregroundStyle(OogoColor.ink)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }
}
