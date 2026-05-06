//
//  CarPlaySceneDelegate.swift
//  Road Tribe
//

import UIKit
import CarPlay

/// Handles CarPlay scene lifecycle — connects and disconnects the CarPlay interface.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private var carPlayManager: CarPlayMapManager?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        carPlayManager = CarPlayMapManager(
            interfaceController: interfaceController,
            locationService: appDelegate?.locationService ?? LocationService(),
            weatherService: RoadWeatherService(),
            voiceChannelService: appDelegate?.voiceChannelService ?? VoiceChannelService(),
            rideTrackingService: appDelegate?.rideTrackingService ?? RideTrackingService()
        )
        carPlayManager?.setupTemplates()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        carPlayManager = nil
    }
}
