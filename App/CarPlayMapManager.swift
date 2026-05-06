//
//  CarPlayMapManager.swift
//  Road Tribe
//

import CarPlay
import MapKit

/// Manages the CarPlay template hierarchy — map, trips list, weather, and voice controls.
class CarPlayMapManager: NSObject {
    private let interfaceController: CPInterfaceController
    private let locationService: LocationService
    private let weatherService: RoadWeatherService
    private let voiceChannelService: VoiceChannelService
    private let rideTrackingService: RideTrackingService

    private var mapTemplate: CPMapTemplate?

    init(
        interfaceController: CPInterfaceController,
        locationService: LocationService,
        weatherService: RoadWeatherService,
        voiceChannelService: VoiceChannelService,
        rideTrackingService: RideTrackingService
    ) {
        self.interfaceController = interfaceController
        self.locationService = locationService
        self.weatherService = weatherService
        self.voiceChannelService = voiceChannelService
        self.rideTrackingService = rideTrackingService
        super.init()
    }

    // MARK: - Setup

    func setupTemplates() {
        // 1. Map Template (primary view)
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self

        // Navigation bar buttons
        let weatherButton = CPBarButton(title: "Weather") { [weak self] _ in
            self?.showWeatherList()
        }
        let voiceButton = CPBarButton(title: "Walkie") { [weak self] _ in
            self?.toggleVoiceChannel()
        }
        mapTemplate.leadingNavigationBarButtons = [weatherButton]
        mapTemplate.trailingNavigationBarButtons = [voiceButton]

        self.mapTemplate = mapTemplate

        // 2. Trips list
        let tripListTemplate = buildTripListTemplate()

        // 3. Tab bar combining both
        let tabBar = CPTabBarTemplate(templates: [mapTemplate, tripListTemplate])
        interfaceController.setRootTemplate(tabBar, animated: true, completion: nil)

        // Fetch weather for CarPlay display
        Task { @MainActor in
            let coord = locationService.currentLocation ?? .sanFrancisco
            await weatherService.fetchWeather(at: coord)
        }
    }

    // MARK: - Trip List

    private func buildTripListTemplate() -> CPListTemplate {
        // Placeholder items — in production, these would come from SwiftData
        let activeItem = CPListItem(
            text: "Active Ride",
            detailText: rideTrackingService.isRiding
                ? "\(rideTrackingService.formattedElapsedTime) · \(String(format: "%.1f mi", rideTrackingService.distanceMiles))"
                : "No active ride",
            image: UIImage(systemName: "motorcycle.fill")
        )

        let planningItem = CPListItem(
            text: "Plan a Trip",
            detailText: "Open Road Tribe on your phone",
            image: UIImage(systemName: "map.fill")
        )

        let section = CPListSection(items: [activeItem, planningItem])
        let template = CPListTemplate(title: "Trips", sections: [section])
        template.tabImage = UIImage(systemName: "motorcycle.fill")
        return template
    }

    // MARK: - Weather

    private func showWeatherList() {
        var items: [CPListItem] = []

        if let condition = weatherService.currentCondition {
            items.append(CPListItem(
                text: "Temperature",
                detailText: "\(condition.temperatureFormatted) (feels like \(condition.feelsLikeFormatted))",
                image: UIImage(systemName: condition.symbolName)
            ))
            items.append(CPListItem(
                text: "Wind",
                detailText: condition.windFormatted,
                image: UIImage(systemName: "wind")
            ))
            items.append(CPListItem(
                text: "Humidity",
                detailText: condition.humidityFormatted,
                image: UIImage(systemName: "humidity.fill")
            ))
            items.append(CPListItem(
                text: "UV Index",
                detailText: "\(condition.uvIndexValue)",
                image: UIImage(systemName: "sun.max.fill")
            ))

            // Ride readiness
            let readiness = weatherService.weatherAlerts.isEmpty ? "Good riding weather" : "Check alerts (\(weatherService.weatherAlerts.count))"
            items.append(CPListItem(
                text: "Ride Status",
                detailText: readiness,
                image: UIImage(systemName: weatherService.weatherAlerts.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            ))
        } else {
            items.append(CPListItem(
                text: "Weather Unavailable",
                detailText: weatherService.lastError ?? "Loading...",
                image: UIImage(systemName: "cloud.fill")
            ))
        }

        // Alerts section
        var sections = [CPListSection(items: items, header: "Current Conditions", sectionIndexTitle: nil)]

        if !weatherService.weatherAlerts.isEmpty {
            let alertItems = weatherService.weatherAlerts.map { alert in
                CPListItem(
                    text: alert.summary,
                    detailText: "Severity: \(alert.severity.rawValue.capitalized)",
                    image: UIImage(systemName: alert.severity.iconName)
                )
            }
            sections.append(CPListSection(items: alertItems, header: "Weather Alerts", sectionIndexTitle: nil))
        }

        let template = CPListTemplate(title: "Weather", sections: sections)
        interfaceController.pushTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Voice Channel

    private func toggleVoiceChannel() {
        if voiceChannelService.isInChannel {
            voiceChannelService.toggleMute()

            let status = voiceChannelService.isMuted ? "Muted" : "Unmuted"
            let alert = CPAlertTemplate(
                titleVariants: [status],
                actions: [CPAlertAction(title: "OK", style: .default) { _ in
                    self.interfaceController.dismissTemplate(animated: true, completion: nil)
                }]
            )
            interfaceController.presentTemplate(alert, animated: true, completion: nil)
        } else {
            let alert = CPAlertTemplate(
                titleVariants: ["No Active Channel"],
                actions: [CPAlertAction(title: "OK", style: .default) { _ in
                    self.interfaceController.dismissTemplate(animated: true, completion: nil)
                }]
            )
            interfaceController.presentTemplate(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - CPMapTemplateDelegate

extension CarPlayMapManager: CPMapTemplateDelegate {
    func mapTemplate(_ mapTemplate: CPMapTemplate, panBeganWith direction: CPMapTemplate.PanDirection) { }
    func mapTemplate(_ mapTemplate: CPMapTemplate, panEndedWith direction: CPMapTemplate.PanDirection) { }
}
