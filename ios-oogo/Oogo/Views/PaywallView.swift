//
//  PaywallView.swift
//  Oogo
//
//  Hooman words on ink. Two prices on paper. One screen, no scroll.
//

import SwiftUI

enum OogoPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "moon"
        case .yearly: return "year"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$9.99"
        case .yearly: return "$39.99"
        }
    }

    var perMonth: String {
        switch self {
        case .monthly: return "$9.99 each moon"
        case .yearly: return "$3.33 each moon"
        }
    }

    var badge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "save 66%"
        }
    }

    /// Line under the button, spelling out what happens after the free week.
    var afterTrial: String {
        switch self {
        case .monthly: return "free 7 day. then $9.99 each moon. stop anytime."
        case .yearly: return "free 7 day. then $39.99 each year. stop anytime."
        }
    }
}

struct PaywallView: View {
    /// Set when oog is still meeting the hooman: no way out but choosing.
    var onFinish: (() -> Void)?

    @Environment(OogoStore.self) private var store
    @Environment(OogoSync.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var plan: OogoPlan = .yearly
    @State private var appeared: Bool = false

    private var isHard: Bool { onFinish != nil }

    var body: some View {
        ZStack {
            OogoColor.ink.ignoresSafeArea()

            GeometryReader { proxy in
                // Quotes get a fixed strip so prices can never be pushed off the bottom.
                let strip = max(min(proxy.size.height * 0.34, 320), 132)

                VStack(spacing: 0) {
                    topRow

                    QuoteMarquee(height: strip)
                        .padding(.top, 10)

                    Spacer(minLength: 8)

                    sheet
                        .offset(y: appeared ? 0 : 26)
                        .opacity(appeared ? 1 : 0)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let motion = reduceMotion ? Animation.easeInOut(duration: 0.2) : OogoMotion.soft
            withAnimation(motion.delay(0.06)) { appeared = true }
        }
    }

    /// Wordmark on ink, with the way out when oog is not gatekeeping.
    private var topRow: some View {
        HStack(alignment: .center) {
            OogoWordmark(diameter: 17, color: Color.white)
            Spacer(minLength: 8)
            if isHard {
                TinyLabel(text: "hooman say", size: 11, color: Color.white.opacity(0.55))
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .background { Circle().fill(Color.white.opacity(0.12)) }
                        .contentShape(.circle)
                }
                .buttonStyle(OogoPressStyle(scale: 0.9))
                .accessibilityLabel("close")
            }
        }
        .frame(height: 38)
        .padding(.horizontal, OogoMetric.margin)
        .padding(.top, 4)
    }

    // MARK: - Paper sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            Text("oogo unlimited")
                .font(OogoFont.heavy(29))
                .oogoTracking(29)
                .foregroundStyle(OogoColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 22)

            Text(isHard ? "hooman commit. oog give week free." : "every move. every plan. no noise.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 4)

            HStack(spacing: 10) {
                ForEach(OogoPlan.allCases) { option in
                    planTile(option)
                }
            }
            .padding(.top, 16)

            HStack(spacing: 8) {
                RedDot(size: 5)
                Text("free 7 day first. oog trust hooman.")
                    .accessibilityLabel("seven day free first")
                    .font(OogoFont.semibold(14.5))
                    .foregroundStyle(OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 14)

            OogoPrimaryButton(title: "start free week", firesHaptic: false) {
                store.isMember = true
                Haptic.success()
                complete()
            }
            .padding(.top, 11)

            Text(plan.afterTrial)
                .font(OogoFont.regular(12.5))
                .monospacedDigit()
                .foregroundStyle(OogoColor.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, 9)

            footer
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, OogoMetric.margin)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32,
                style: .continuous
            )
            .fill(OogoColor.page)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func planTile(_ option: OogoPlan) -> some View {
        let isSelected = plan == option
        return Button {
            Haptic.select()
            withAnimation(OogoMotion.snap) { plan = option }
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(option.title)
                    .font(OogoFont.semibold(14))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : OogoColor.secondaryText)
                Text(option.price)
                    .font(OogoFont.number(25))
                    .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(option.perMonth)
                    .font(OogoFont.regular(12.5))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : OogoColor.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                    .fill(isSelected ? OogoColor.ink : OogoColor.paper)
                    .overlay {
                        RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                            .strokeBorder(isSelected ? Color.clear : OogoColor.mist, lineWidth: 1.2)
                    }
            }
            .overlay(alignment: .topTrailing) {
                if let badge = option.badge {
                    Text(badge)
                        .font(OogoFont.semibold(11))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 9)
                        .frame(height: 22)
                        .background { Capsule().fill(OogoColor.red) }
                        .offset(x: -8, y: -9)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(OogoPressStyle(scale: 0.97))
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                Haptic.firm()
                store.isMember = true
                complete()
            } label: {
                Text("restore")
                    .font(OogoFont.regular(13))
                    .foregroundStyle(OogoColor.secondaryText)
            }
            .buttonStyle(OogoPressStyle(scale: 0.95))

            dot
            footerLink("terms")
            dot
            footerLink("privacy")
        }
    }

    private var dot: some View {
        Circle()
            .fill(OogoColor.secondaryText.opacity(0.5))
            .frame(width: 3, height: 3)
    }

    private func footerLink(_ title: String) -> some View {
        Button {
        } label: {
            Text(title)
                .font(OogoFont.regular(13))
                .foregroundStyle(OogoColor.secondaryText)
        }
        .buttonStyle(OogoPressStyle(scale: 0.95))
    }

    private func complete() {
        // Signed-out hoomans just keep it locally; the next sync carries it up.
        Task { await sync.pushMembership() }
        if let onFinish {
            onFinish()
        } else {
            dismiss()
        }
    }
}

// MARK: - Quote marquee

/// Real hooman words drifting slow up the ink, looping forever.
private struct QuoteMarquee: View {
    /// Fixed strip the words drift through.
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var loopHeight: CGFloat = 0
    @State private var isRolling: Bool = false

    private let spacing: CGFloat = 10

    /// Sent by hoomans who train. Printed exactly as they wrote it.
    private let quotes: [String] = [
        "man I'm sooooo sore rn but at the same time feel soooo euphoric after the workout... OOGO is a BEAST!!!",
        "just wrapped up day 1 kettlebells finished me FULLY",
        "Day 4, it looked way more simple on my phone. Got up early to do this because I have a very busy day today. Thank you for doing this. I told myself I would be happy if I lost 5 lbs in 30 days. (Plus I'm eating better). I'm down 1.5 already."
    ]

    /// Constant drift speed no matter how long the words are.
    private var duration: Double {
        max(Double(loopHeight) / 22.0, 8)
    }

    var body: some View {
        strip
            // Words keep their own height, then the strip cuts them clean.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: height, alignment: .top)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.4), location: 0),
                        .init(color: .black, location: 0.14),
                        .init(color: .black, location: 0.72),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .onChange(of: loopHeight) { _, measured in
                guard !reduceMotion, measured > 0, !isRolling else { return }
                isRolling = true
            }
    }

    private var strip: some View {
        VStack(spacing: spacing) {
            column
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { measured in
                    loopHeight = measured + spacing
                }

            if !reduceMotion {
                column
            }
        }
        .padding(.horizontal, OogoMetric.margin)
        .offset(y: isRolling ? -loopHeight : 0)
        .animation(
            reduceMotion ? nil : .linear(duration: duration).repeatForever(autoreverses: false),
            value: isRolling
        )
    }

    private var column: some View {
        VStack(spacing: spacing) {
            ForEach(Array(quotes.enumerated()), id: \.offset) { _, quote in
                card(quote)
            }
        }
    }

    private func card(_ quote: String) -> some View {
        Text(quote)
            .font(OogoFont.medium(15.5))
            .foregroundStyle(Color.white)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    }
            }
    }
}
