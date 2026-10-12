//
//  WorkPoster.swift
//  Oogo
//
//  Training receipt. Ink on paper, drawn fresh and handed to the phone.
//

import SwiftUI
import UIKit

/// Everything printed on a share card.
nonisolated struct WorkPosterData {
    nonisolated let dayName: String
    nonisolated let dateText: String
    nonisolated let rankName: String?
    nonisolated let rounds: Int
    nonisolated let timeText: String
    nonisolated let bellText: String
    nonisolated let moves: [String]
    /// How the work felt, if the hooman said.
    nonisolated let feelText: String?

    /// Card for a finished session, using the hooman's current rank.
    nonisolated static func make(
        dayType: DayType,
        date: Date,
        rankName: String?,
        rounds: Int,
        durationSeconds: Int,
        bellText: String,
        moves: [String],
        feel: String?
    ) -> WorkPosterData {
        let cleanFeel = feel?.trimmingCharacters(in: .whitespaces).lowercased()
        return WorkPosterData(
            dayName: dayType.shortName.lowercased(),
            dateText: date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)).lowercased(),
            rankName: rankName,
            rounds: rounds,
            timeText: SessionRunner.minutesText(durationSeconds),
            bellText: bellText,
            moves: moves.map { $0.lowercased() },
            feelText: (cleanFeel?.isEmpty ?? true) ? nil : cleanFeel
        )
    }
}

/// Portrait training receipt: date, day word, three numbers, moves, mark.
struct WorkPoster: View {
    let data: WorkPosterData

    /// Card size in points. Rendered at 3× for a 1080 × 1920 image.
    static let size: CGSize = CGSize(width: 360, height: 640)

    private let margin: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 18)

            numbers

            Spacer(minLength: 18)

            rule

            moveList
                .padding(.top, 16)

            if let feelText = data.feelText {
                Text("felt \(feelText)")
                    .font(OogoFont.regular(13))
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.top, 16)
            }

            Spacer(minLength: 18)

            foot
        }
        .padding(margin)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .background(OogoColor.paper)
    }

    // MARK: - Head

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(data.dateText)
                .font(OogoFont.semibold(11.5))
                .tracking(1.9)
                .textCase(.uppercase)
                .foregroundStyle(OogoColor.secondaryText)

            Text("\(data.dayName) done.")
                .font(OogoFont.heavy(54))
                .tracking(-1.9)
                .foregroundStyle(OogoColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.top, 9)

            if let rankName = data.rankName {
                HStack(spacing: 7) {
                    Circle()
                        .fill(OogoColor.red)
                        .frame(width: 5, height: 5)
                    Text(rankName)
                        .font(OogoFont.semibold(13.5))
                        .foregroundStyle(OogoColor.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.top, 9)
            }
        }
    }

    // MARK: - Numbers

    private var numbers: some View {
        VStack(spacing: 0) {
            rule

            HStack(alignment: .top, spacing: 0) {
                number("\(data.rounds)", "round")
                hairline
                number(data.timeText, "time")
                hairline
                number(data.bellText, "bell")
            }
            .padding(.vertical, 18)

            rule
        }
    }

    private func number(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(OogoFont.number(29))
                .foregroundStyle(OogoColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(OogoFont.semibold(10.5))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(OogoColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hairline: some View {
        Rectangle()
            .fill(OogoColor.mist)
            .frame(width: 1, height: 38)
            .padding(.trailing, 14)
    }

    private var rule: some View {
        Rectangle()
            .fill(OogoColor.mist)
            .frame(height: 1)
    }

    // MARK: - Moves

    private var moveList: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(data.moves.prefix(6).enumerated()), id: \.offset) { _, move in
                HStack(spacing: 11) {
                    Rectangle()
                        .fill(OogoColor.ink)
                        .frame(width: 11, height: 1.5)
                    Text(move)
                        .font(OogoFont.medium(16))
                        .foregroundStyle(OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
        }
    }

    // MARK: - Foot

    private var foot: some View {
        VStack(alignment: .leading, spacing: 0) {
            rule

            HStack(spacing: 9) {
                OogoWordmark(diameter: 13)
                Spacer(minLength: 8)
                Text("swing bell. get strong.")
                    .font(OogoFont.regular(12))
                    .foregroundStyle(OogoColor.secondaryText)
            }
            .padding(.top, 15)
        }
    }
}

// MARK: - Share sheet

/// Shows the card, then hands the image to the phone.
struct WorkPosterSheet: View {
    let data: WorkPosterData

    @Environment(\.dismiss) private var dismiss
    @State private var poster: Image?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    TinyLabel(text: "show tribe")
                    Text("share work")
                        .font(OogoFont.heavy(28))
                        .oogoTracking(28)
                        .foregroundStyle(OogoColor.ink)
                }
                Spacer()
                OogoCloseButton { dismiss() }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.top, 22)
            .padding(.bottom, 14)

            GeometryReader { proxy in
                let scale = min(
                    proxy.size.width / WorkPoster.size.width,
                    proxy.size.height / WorkPoster.size.height
                )
                WorkPoster(data: data)
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(.rect(cornerRadius: OogoRadius.card * scale, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: OogoRadius.card * scale, style: .continuous)
                            .strokeBorder(OogoColor.mist, lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 10)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.bottom, 18)

            Group {
                if let poster {
                    ShareLink(
                        item: poster,
                        preview: SharePreview("\(data.dayName) done.", image: poster)
                    ) {
                        HStack(spacing: 12) {
                            Text("send it")
                                .font(OogoFont.bodyStrong)
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: OogoMetric.buttonHeight)
                        .background {
                            Capsule(style: .continuous)
                                .fill(OogoColor.ink)
                                .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
                        }
                        .contentShape(.capsule)
                    }
                    .buttonStyle(OogoPressStyle())
                    .simultaneousGesture(TapGesture().onEnded { Haptic.firm() })
                } else {
                    Text("oog draw card…")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                        .frame(height: OogoMetric.buttonHeight)
                }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.bottom, 20)
        }
        .background(OogoColor.page)
        .presentationDetents([.large])
        .task { render() }
    }

    /// Draws the card at 3× so it stays crisp in any feed.
    private func render() {
        guard poster == nil else { return }
        let renderer = ImageRenderer(content: WorkPoster(data: data))
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        poster = Image(uiImage: image)
    }
}
