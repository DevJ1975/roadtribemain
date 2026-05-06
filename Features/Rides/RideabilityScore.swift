//
//  RideabilityScore.swift
//  Road Tribe
//

import SwiftUI

// MARK: - Scoring Engine

/// Computes a 0–100 "is today good for riding?" score from current weather conditions.
struct RideabilityScore {

    let score: Int            // 0–100
    let label: String         // "Excellent", "Good", "Borderline", "Stay Home"
    let color: Color
    let factors: [Factor]

    struct Factor: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
        let penalty: Int      // how many points this factor knocked off (0 = none)
    }

    static func compute(from condition: CurrentConditionInfo) -> RideabilityScore {
        var total = 100
        var factors: [Factor] = []

        // Temperature: ideal 60–85°F
        let temp = condition.temperature
        let tempPenalty: Int
        let tempDetail: String
        if temp < 32 {
            tempPenalty = 50; tempDetail = "\(Int(temp))°F — dangerously cold"
        } else if temp < 45 {
            tempPenalty = 30; tempDetail = "\(Int(temp))°F — very cold"
        } else if temp < 55 {
            tempPenalty = 15; tempDetail = "\(Int(temp))°F — chilly"
        } else if temp > 100 {
            tempPenalty = 30; tempDetail = "\(Int(temp))°F — extreme heat"
        } else if temp > 95 {
            tempPenalty = 15; tempDetail = "\(Int(temp))°F — very hot"
        } else {
            tempPenalty = 0; tempDetail = "\(Int(temp))°F — comfortable"
        }
        total -= tempPenalty
        factors.append(Factor(icon: "thermometer.medium", title: "Temperature",
                              detail: tempDetail, penalty: tempPenalty))

        // Wind: calm is ideal, 25+ mph crosswind is dangerous
        let wind = condition.windSpeedMPH
        let windPenalty: Int
        let windDetail: String
        if wind >= 35 {
            windPenalty = 40; windDetail = "\(Int(wind)) mph — dangerous"
        } else if wind >= 25 {
            windPenalty = 25; windDetail = "\(Int(wind)) mph — challenging"
        } else if wind >= 15 {
            windPenalty = 10; windDetail = "\(Int(wind)) mph — breezy"
        } else {
            windPenalty = 0; windDetail = "\(Int(wind)) mph — calm"
        }
        total -= windPenalty
        factors.append(Factor(icon: "wind", title: "Wind",
                              detail: windDetail, penalty: windPenalty))

        // Rain chance
        // We don't have rain chance in CurrentConditionInfo directly, but we can
        // approximate from conditionDescription keywords
        let desc = condition.conditionDescription.lowercased()
        let rainPenalty: Int
        let rainDetail: String
        if desc.contains("thunder") || desc.contains("storm") {
            rainPenalty = 50; rainDetail = "Thunderstorm — stay home"
        } else if desc.contains("heavy rain") || desc.contains("heavy drizzle") {
            rainPenalty = 40; rainDetail = "Heavy rain — dangerous"
        } else if desc.contains("rain") || desc.contains("drizzle") || desc.contains("shower") {
            rainPenalty = 25; rainDetail = "Rain in the area"
        } else if desc.contains("snow") || desc.contains("sleet") || desc.contains("ice") || desc.contains("hail") {
            rainPenalty = 60; rainDetail = "Winter precipitation — do not ride"
        } else if desc.contains("fog") || desc.contains("mist") {
            rainPenalty = 20; rainDetail = "Reduced visibility"
        } else {
            rainPenalty = 0; rainDetail = "Clear / dry"
        }
        total -= rainPenalty
        factors.append(Factor(icon: "cloud.rain.fill", title: "Precipitation",
                              detail: rainDetail, penalty: rainPenalty))

        // UV Index — awareness only, no penalty
        let uvLevel: String
        switch condition.uvIndexValue {
        case 0...2: uvLevel = "Low (\(condition.uvIndexValue))"
        case 3...5: uvLevel = "Moderate (\(condition.uvIndexValue))"
        case 6...7: uvLevel = "High (\(condition.uvIndexValue))"
        case 8...10: uvLevel = "Very High (\(condition.uvIndexValue))"
        default: uvLevel = "Extreme (\(condition.uvIndexValue))"
        }
        factors.append(Factor(icon: "sun.max.fill", title: "UV Index",
                              detail: uvLevel, penalty: 0))

        let clamped = max(0, min(100, total))

        let (label, color): (String, Color)
        switch clamped {
        case 80...100: (label, color) = ("Excellent", .green)
        case 60..<80:  (label, color) = ("Good", Color(red: 0.6, green: 0.8, blue: 0.2))
        case 40..<60:  (label, color) = ("Borderline", .orange)
        default:       (label, color) = ("Stay Home", .red)
        }

        return RideabilityScore(score: clamped, label: label, color: color, factors: factors)
    }
}

// MARK: - Card View

/// Compact card showing today's rideability score with a breakdown of factors.
struct RideabilityCard: View {
    let score: RideabilityScore
    @State private var showingDetail = false

    var body: some View {
        Button { showingDetail = true } label: {
            HStack(spacing: Spacing.sm) {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(score.color.opacity(0.2), lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: CGFloat(score.score) / 100)
                        .stroke(score.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    VStack(spacing: 0) {
                        Text("\(score.score)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(score.color)
                        Text("/100")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                // Label + factors summary
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "motorcycle.fill")
                            .foregroundStyle(score.color)
                            .font(.subheadline)
                        Text(score.label)
                            .font(.rtTitle)
                            .foregroundStyle(score.color)
                    }
                    Text("Rideability today")
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.xs) {
                        ForEach(score.factors.filter { $0.penalty > 0 }.prefix(2)) { factor in
                            Label(factor.title, systemImage: factor.icon)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.8), in: Capsule())
                        }
                        if score.factors.filter({ $0.penalty > 0 }).isEmpty {
                            Label("All clear", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green, in: Capsule())
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.sm)
            .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            RideabilityDetailSheet(score: score)
        }
    }
}

// MARK: - Detail Sheet

private struct RideabilityDetailSheet: View {
    let score: RideabilityScore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Big score ring
                    ZStack {
                        Circle()
                            .stroke(score.color.opacity(0.15), lineWidth: 16)
                            .frame(width: 160, height: 160)
                        Circle()
                            .trim(from: 0, to: CGFloat(score.score) / 100)
                            .stroke(score.color,
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 160, height: 160)
                        VStack(spacing: 2) {
                            Text("\(score.score)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(score.color)
                            Text(score.label)
                                .font(.rtTitle)
                                .foregroundStyle(score.color)
                        }
                    }
                    .padding(.top, Spacing.lg)

                    // Factor breakdown
                    VStack(spacing: Spacing.xs) {
                        ForEach(score.factors) { factor in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: factor.icon)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.title3)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(factor.title)
                                        .font(.rtTitle)
                                    Text(factor.detail)
                                        .font(.rtCaption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if factor.penalty > 0 {
                                    Text("-\(factor.penalty)")
                                        .font(.rtCaptionBold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, Spacing.xxs)
                                        .padding(.vertical, Spacing.xxxs)
                                        .background(Color.red.opacity(0.8), in: Capsule())
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(Spacing.sm)
                            .background(Color.rtSurfaceFallback,
                                        in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("Rideability Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
