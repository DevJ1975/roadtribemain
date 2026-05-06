//
//  DesignSystem.swift
//  Road Tribe
//
//  PLACEHOLDER — these tokens are referenced throughout the app but the
//  authoritative design system was not part of the uploaded source set.
//  The values below are reasonable defaults so the project compiles; they
//  should be replaced with the project's real tokens before shipping.
//

import SwiftUI
import UIKit

/// App-wide design tokens (spacing, colours, icon names, haptics).
enum DesignSystem {

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 6
        static let sm:  CGFloat = 10
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32

        static let tabBarHeight: CGFloat = 56
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small:  CGFloat = 8
        static let medium: CGFloat = 12
        static let large:  CGFloat = 20
    }

    // MARK: - Colours

    enum Colors {
        static let brand   = Color.orange
        static let accent  = Color.blue
        static let success = Color.green
        static let warning = Color.yellow
        static let danger  = Color.red
    }

    // MARK: - Icons

    enum Icons {
        static let challenge = "trophy.fill"
        static let event     = "calendar"
        static let rating    = "star.fill"
        static let hazard    = "exclamationmark.triangle.fill"
        static let sos       = "sos"
        static let streak    = "flame.fill"
        static let badge     = "rosette"
        static let receipt   = "bag.fill"
        static let feed      = "text.bubble.fill"
    }

    // MARK: - Haptics

    enum Haptics {
        static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        static func rigid()   { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
        static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    }
}

// MARK: - Top-level aliases used by some views

/// Top-level alias kept for views that reference `Spacing.*` directly
/// (instead of `DesignSystem.Spacing.*`).
typealias Spacing = DesignSystem.Spacing

/// Top-level alias kept for views that reference `CornerRadius.*` directly.
typealias CornerRadius = DesignSystem.CornerRadius

// MARK: - Typography

extension Font {
    static let rtTitle       = Font.title.weight(.bold)
    static let rtHeadline    = Font.headline
    static let rtBody        = Font.body
    static let rtCaption     = Font.caption
    static let rtCaptionBold = Font.caption.weight(.semibold)
}
