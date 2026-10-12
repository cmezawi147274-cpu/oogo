//
//  GateView.swift
//  Oogo
//
//  The wall between meeting oog and answering oog. No way past but signing in.
//

import SwiftUI

/// Sign-in wall shown once, right after the welcome screen. Two doors in,
/// no skip. Failure stays a quiet line rather than a shouting box.
struct GateView: View {
    /// Passes true when the sky already holds a plan for this hooman, so the
    /// questions can be skipped entirely.
    let onSignedIn: (Bool) -> Void

    @Environment(AuthManager.self) private var auth
    @Environment(OogoSync.self) private var sync
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared: Bool = false
    /// Signed in, now reading the sky before deciding where to send the hooman.
    @State private var isLookingForWall: Bool = false

    /// Reasons oog wants a name on the wall. Short, in order of weight.
    private let reasons: [String] = [
        "work never lost.",
        "new phone, wall come too.",
        "rank keep climbing.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("oog keep work safe.")
                .font(OogoFont.heavy(34))
                .oogoTracking(34)
                .foregroundStyle(OogoColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Text("hooman swing bell. oog write on cave wall. wall live in sky, not just phone.")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 13) {
                ForEach(Array(reasons.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 12) {
                        RedDot(size: 6)
                        Text(line)
                            .font(OogoFont.body)
                            .foregroundStyle(OogoColor.ink)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(
                        entrance.delay(reduceMotion ? 0 : 0.06 * Double(index) + 0.1),
                        value: appeared
                    )
                }
            }
            .padding(.top, 26)

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                doorButton(
                    title: "go in with apple",
                    symbol: "apple.logo",
                    isDark: true,
                    provider: "apple"
                )
                doorButton(
                    title: "go in with google",
                    symbol: "g.circle.fill",
                    isDark: false,
                    provider: "google"
                )

                Text(footnote)
                    .font(OogoFont.caption)
                    .foregroundStyle(auth.showError ? OogoColor.red : OogoColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                    .animation(OogoMotion.snap, value: auth.showError)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(entrance.delay(reduceMotion ? 0 : 0.28), value: appeared)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, OogoMetric.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { appeared = true }
        .onChange(of: auth.isSignedIn) { _, isIn in
            guard isIn, !isLookingForWall else { return }
            Haptic.success()
            isLookingForWall = true
            Task {
                await sync.sync()
                isLookingForWall = false
                onSignedIn(sync.foundExistingPlan)
            }
        }
    }

    private var entrance: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft
    }

    /// Error takes the line when there is one, otherwise the quiet promise.
    private var footnote: String {
        if isLookingForWall {
            return "oog look for hooman wall…"
        }
        if auth.showError {
            return auth.errorMessage.isEmpty ? "door stuck. try again." : auth.errorMessage
        }
        return "oog take name and email. nothing else."
    }

    /// Both doors lock while oog talks to the sky.
    private var isBusy: Bool { auth.isSigningIn || isLookingForWall }

    private func doorButton(title: String, symbol: String, isDark: Bool, provider: String) -> some View {
        Button {
            Haptic.firm()
            auth.showError = false
            Task { await auth.signIn(provider: provider) }
        } label: {
            HStack(spacing: 10) {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(isDark ? Color.white : OogoColor.ink)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .medium))
                }
                Text(title)
                    .font(OogoFont.bodyStrong)
            }
            .foregroundStyle(isDark ? Color.white : OogoColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: OogoMetric.buttonHeight)
            .background {
                Capsule(style: .continuous)
                    .fill(isDark ? OogoColor.ink : OogoColor.paper)
                    .shadow(color: Color.black.opacity(isDark ? 0.18 : 0), radius: 16, x: 0, y: 8)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(isDark ? Color.clear : OogoColor.ink, lineWidth: 1.6)
                    }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(OogoPressStyle())
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1)
        .accessibilityLabel(title)
    }
}
