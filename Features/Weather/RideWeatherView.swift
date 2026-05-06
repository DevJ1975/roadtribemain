//
//  RideWeatherView.swift
//  Road Tribe
//
//  Full-screen weather detail — current conditions, hourly forecast, and
//  any active alerts for the rider's location. Driven by `RoadWeatherService`.
//

import SwiftUI

struct RideWeatherView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var locationService
    @State private var weather = RoadWeatherService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    if weather.isLoading && weather.currentCondition == nil {
                        ProgressView("Fetching forecast…")
                            .padding(DesignSystem.Spacing.lg)
                    }

                    if let condition = weather.currentCondition {
                        currentCard(condition)
                        if !weather.hourlyForecast.isEmpty {
                            hourlySection
                        }
                    }

                    if !weather.weatherAlerts.isEmpty {
                        alertsSection
                    }

                    if let error = weather.lastError, weather.currentCondition == nil {
                        ContentUnavailableView(
                            "Weather Unavailable",
                            systemImage: "cloud.fill",
                            description: Text(error)
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .navigationTitle("Ride Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await weather.fetchWeather(at: locationService.currentLocation ?? .sanFrancisco)
            }
        }
    }

    // MARK: - Current

    private func currentCard(_ c: CurrentConditionInfo) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: c.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 56))
            Text(c.temperatureFormatted).font(.system(size: 44, weight: .heavy))
            Text(c.conditionDescription).font(.rtBody).foregroundStyle(.secondary)
            HStack(spacing: DesignSystem.Spacing.md) {
                Label("Feels \(c.feelsLikeFormatted)", systemImage: "thermometer")
                Label(c.windFormatted, systemImage: "wind")
                Label(c.humidityFormatted, systemImage: "humidity.fill")
            }
            .font(.rtCaption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }

    // MARK: - Hourly

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Hourly Forecast").font(.rtHeadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(weather.hourlyForecast) { hour in
                        VStack(spacing: 4) {
                            Text(hour.timeFormatted).font(.rtCaption)
                            Image(systemName: hour.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            Text(hour.tempFormatted).font(.rtCaptionBold)
                            Text(hour.precipFormatted)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 56)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Label("Weather Alerts", systemImage: "exclamationmark.triangle.fill")
                .font(.rtHeadline)
                .foregroundStyle(DesignSystem.Colors.warning)
            ForEach(weather.weatherAlerts) { alert in
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.summary).font(.rtCaptionBold)
                    Text("Source: \(alert.source) · \(alert.severity.rawValue.capitalized)")
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)
                }
                .padding(DesignSystem.Spacing.xs)
                .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            }
        }
    }
}
