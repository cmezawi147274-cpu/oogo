//
//  OogoTheme.swift
//  Oogo
//
//  Design tokens: colors, type scale, surfaces, motion, haptics.
//

import SwiftUI
import UIKit

extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `0xE53935`.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

/// The OOGO palette. Ink + paper, one red spark.
enum OogoColor {
    static let ink = Color(hex: 0x111111)
    static let paper = Color.white
    static let cloud = Color(hex: 0xF1F1EF)
    static let mist = Color(hex: 0xE6E6E3)
    static let secondaryText = Color(hex: 0x6A6A66)
    static let red = Color(hex: 0xE53935)
    static let page = Color(hex: 0xFAFAF9)
    static let disabled = Color(hex: 0xD4D4D0)
}

/// One rounded type scale, used everywhere. Every size scales with Dynamic Type.
enum OogoFont {
    // MARK: Display — screen titles and hero numbers

    /// 42pt heavy. Hero statements only, one per screen.
    static var displayXL: Font { scaled(42, .heavy, relativeTo: .largeTitle) }
    /// 34pt heavy. Screen titles.
    static var display: Font { scaled(34, .heavy, relativeTo: .largeTitle) }
    /// 27pt heavy. Card headlines, movement names.
    static var title: Font { scaled(27, .heavy, relativeTo: .title2) }
    /// 21pt bold. Section headings.
    static var heading: Font { scaled(21, .bold, relativeTo: .title3) }

    // MARK: Body scale

    /// 17.5pt semibold. Row titles, buttons.
    static var bodyStrong: Font { scaled(17.5, .semibold, relativeTo: .body) }
    /// 17pt medium. Standard row text.
    static var body: Font { scaled(17, .medium, relativeTo: .body) }
    /// 16.5pt regular. Subtitles, paragraphs.
    static var subtitle: Font { scaled(16.5, .regular, relativeTo: .body) }
    /// 14.5pt regular. Supporting detail.
    static var caption: Font { scaled(14.5, .regular, relativeTo: .footnote) }
    /// 11.5pt semibold. Tracked uppercase labels.
    static var tiny: Font { scaled(11.5, .semibold, relativeTo: .caption2) }

    // MARK: Numerals — even-width so counters never twitch

    /// Large counting number, monospaced digits.
    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }

    /// Timer face, monospaced digits.
    static func timer(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }

    // MARK: Escape hatches for one-off sizes

    static func heavy(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }

    /// Scales with the hooman's text size setting, capped so big type never breaks layout.
    private static func scaled(_ size: CGFloat, _ weight: Font.Weight, relativeTo style: UIFont.TextStyle) -> Font {
        let scaled = UIFontMetrics(forTextStyle: style).scaledValue(for: size)
        return .system(size: min(scaled, size * 1.3), weight: weight, design: .rounded)
    }
}

/// Optical letter spacing. Big rounded type needs to be pulled tighter.
enum OogoTracking {
    static func forSize(_ size: CGFloat) -> CGFloat {
        switch size {
        case ..<20: return 0
        case ..<28: return -0.5
        case ..<36: return -0.9
        default: return -1.4
        }
    }
}

enum OogoRadius {
    static let card: CGFloat = 24
    static let smallCard: CGFloat = 18
    static let nav: CGFloat = 30
}

enum OogoMetric {
    static let margin: CGFloat = 20
    static let cardGap: CGFloat = 12
    static let sectionGap: CGFloat = 26
    static let buttonHeight: CGFloat = 58
    static let chipHeight: CGFloat = 44
    /// Space reserved at the bottom of scroll content for the floating nav bar.
    static let navClearance: CGFloat = 118
}

// MARK: - Surfaces

/// White rounded card that floats: wide soft shadow, barely-there hairline.
struct OogoCardBackground: ViewModifier {
    var radius: CGFloat = OogoRadius.card
    var isElevated: Bool = true

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(OogoColor.paper)
                    .shadow(color: Color.black.opacity(isElevated ? 0.055 : 0), radius: 22, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(isElevated ? 0.035 : 0), radius: 4, x: 0, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(OogoColor.mist.opacity(0.7), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func oogoCard(radius: CGFloat = OogoRadius.card, isElevated: Bool = true) -> some View {
        modifier(OogoCardBackground(radius: radius, isElevated: isElevated))
    }

    /// Applies optical tracking matched to the font size.
    func oogoTracking(_ size: CGFloat) -> some View {
        tracking(OogoTracking.forSize(size))
    }
}

// MARK: - Motion

enum OogoMotion {
    /// Quick, decisive. Selection and value changes.
    static let snap: Animation = .spring(response: 0.34, dampingFraction: 0.8)
    /// Calm arrival. Entrances, layout shifts.
    static let soft: Animation = .spring(response: 0.55, dampingFraction: 0.88)
    /// Springy. Press feedback, dot fills.
    static let pop: Animation = .spring(response: 0.28, dampingFraction: 0.6)
    /// Long, gentle loop. Breathing dots.
    static let breathe: Animation = .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
}

/// Scale-down press feedback used on every tappable OOGO surface.
struct OogoPressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(OogoMotion.pop, value: configuration.isPressed)
    }
}

// MARK: - Haptics

/// OOGO's feel vocabulary. Weight matches importance, and nothing fires twice
/// for one action. Plain navigation — back arrows, closing sheets, scrolling —
/// stays silent on purpose.
///
/// - `tick` / `select`: feather-light. Steppers, chips, picking a move.
/// - `firm`: medium. Meaningful actions worth feeling — work starts, round lands.
/// - `done`: strongest. Work finished, commitment sealed.
enum Haptic {
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private static let softGen = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidGen = UIImpactFeedbackGenerator(style: .rigid)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let noticeGen = UINotificationFeedbackGenerator()

    /// Warms the taptic engine so the next hit lands without lag.
    /// Call just before a hold or a run of timed feedback.
    static func prime() {
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        softGen.prepare()
    }

    /// Feather-light. Number steps, small toggles, quiet confirmations.
    static func tick() {
        rigidGen.prepare()
        rigidGen.impactOccurred(intensity: 0.45)
    }

    /// Light knock. Ordinary taps that open or close something meaningful.
    static func tap() {
        lightGen.prepare()
        lightGen.impactOccurred(intensity: 0.7)
    }

    /// Medium. Actions that change the plan or move work forward.
    static func firm() {
        mediumGen.prepare()
        mediumGen.impactOccurred()
    }

    /// The heaviest hit OOGO uses. Work done, commitment sealed.
    static func done() {
        heavyGen.prepare()
        heavyGen.impactOccurred(intensity: 1)
    }

    /// Cushioned pulse at a chosen strength. Used for rising runs.
    static func soft(intensity: CGFloat) {
        softGen.prepare()
        softGen.impactOccurred(intensity: max(0.2, min(intensity, 1)))
    }

    /// Picker movement. Cheapest feedback there is.
    static func select() {
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }

    static func success() {
        noticeGen.notificationOccurred(.success)
    }
}
