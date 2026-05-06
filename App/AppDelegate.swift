//
//  AppDelegate.swift
//  Road Tribe
//
//  UIApplicationDelegate stub used by the CarPlay scene to access shared
//  service instances. The SwiftUI App lifecycle is the primary entry point;
//  this exists only because CarPlay still goes through UIKit scene config.
//

import UIKit
import CarPlay

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

    /// Shared services used by both the SwiftUI app and CarPlay scene.
    /// Hooked up from the SwiftUI `App` body so both UIs see the same state.
    @MainActor var locationService: LocationService = LocationService()
    @MainActor var voiceChannelService: VoiceChannelService = VoiceChannelService()
    @MainActor var rideTrackingService: RideTrackingService = RideTrackingService()
    @MainActor var weatherService: RoadWeatherService = RoadWeatherService()

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay", sessionRole: .carTemplateApplication)
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
}
