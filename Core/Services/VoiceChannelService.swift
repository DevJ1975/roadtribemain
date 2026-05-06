//
//  VoiceChannelService.swift
//  Road Tribe
//

import AVFoundation
import Foundation
import SwiftData
import UIKit

/// Manages voice channel state with simulated VoIP behavior and voice activity detection.
/// In production, this would integrate with a real VoIP service (e.g., Twilio, Agora).
@Observable
final class VoiceChannelService {
    var activeChannel: VoiceChannel?
    var isMuted = false
    var isSpeaking = false
    var currentSpeakerID: UUID?
    var currentSpeakerName: String?
    var connectedParticipantIDs: Set<UUID> = []

    /// Current mic input level (0.0–1.0) for the level meter UI.
    var micLevel: Float = 0

    var isInChannel: Bool { activeChannel != nil }

    private var simulationTask: Task<Void, Never>?
    private var speakerNames: [UUID: String] = [:]
    private var selfID: UUID?

    // MARK: - Voice Activity Detection

    private var audioEngine: AVAudioEngine?
    private var vadTask: Task<Void, Never>?

    /// Normalized input level above which we consider the user "speaking".
    private let vadThreshold: Float = 0.03
    /// How long (seconds) input must stay below threshold before we stop speaking.
    private let vadSilenceTimeout: TimeInterval = 0.6

    private var lastAboveThresholdDate: Date?
    private var lastLevelUpdateDate: Date = .distantPast

    /// Join a voice channel for a trip.
    func joinChannel(_ channel: VoiceChannel, userID: UUID, participants: [UUID: String]) {
        activeChannel = channel
        isMuted = false
        isSpeaking = false
        selfID = userID
        speakerNames = participants

        // Add self and simulate others connecting
        connectedParticipantIDs = [userID]
        simulateOthersJoining(channel: channel, selfID: userID)
        startSpeakingSimulation(selfID: userID)
        startVoiceActivityDetection()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Leave the active voice channel.
    func leaveChannel() {
        simulationTask?.cancel()
        simulationTask = nil
        stopVoiceActivityDetection()
        activeChannel = nil
        isMuted = false
        isSpeaking = false
        currentSpeakerID = nil
        currentSpeakerName = nil
        connectedParticipantIDs = []
        speakerNames = [:]
        selfID = nil

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Toggle mute state.
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            isSpeaking = false
            if currentSpeakerID == selfID {
                currentSpeakerID = nil
                currentSpeakerName = nil
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Audio Engine VAD

    private func startVoiceActivityDetection() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            return
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let level = self.rmsLevel(buffer: buffer)
            Task { @MainActor [weak self] in
                self?.processAudioLevel(level)
            }
        }

        do {
            try engine.start()
            self.audioEngine = engine
        } catch {
            return
        }
    }

    private func stopVoiceActivityDetection() {
        vadTask?.cancel()
        vadTask = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        micLevel = 0

        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Calculate RMS (root mean square) level from an audio buffer.
    private func rmsLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frames {
            let sample = channelData[0][i]
            sum += sample * sample
        }
        return sqrt(sum / Float(frames))
    }

    /// Process the audio level on the main actor — trigger speaking state.
    @MainActor
    private func processAudioLevel(_ level: Float) {
        guard activeChannel != nil, !isMuted else {
            micLevel = 0
            return
        }

        // Throttle UI-level updates to ~15 fps to avoid excessive redraws
        let now = Date()
        let amplified = level * 5.0
        if now.timeIntervalSince(lastLevelUpdateDate) >= 0.066 || abs(amplified - micLevel) > 0.1 {
            micLevel = amplified
            lastLevelUpdateDate = now
        }

        guard let userID = selfID else { return }

        if level >= vadThreshold {
            lastAboveThresholdDate = .now

            if !isSpeaking {
                // Start speaking
                isSpeaking = true
                currentSpeakerID = userID
                currentSpeakerName = speakerNames[userID] ?? "You"
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        } else if isSpeaking, currentSpeakerID == userID {
            // Check if silence has lasted long enough to stop
            let silenceDuration = Date.now.timeIntervalSince(lastAboveThresholdDate ?? .distantPast)
            if silenceDuration >= vadSilenceTimeout {
                isSpeaking = false
                currentSpeakerID = nil
                currentSpeakerName = nil
            }
        }
    }

    // MARK: - Simulation

    /// Simulate other riders connecting after a short delay.
    private func simulateOthersJoining(channel: VoiceChannel, selfID: UUID) {
        let otherIDs = channel.participantIDs.filter { $0 != selfID }
        for (index, riderID) in otherIDs.enumerated() {
            let delay = Double(index + 1) * 1.2
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard let self, self.activeChannel != nil else { return }
                self.connectedParticipantIDs.insert(riderID)
            }
        }
    }

    /// Simulate other riders speaking at random intervals.
    private func startSpeakingSimulation(selfID: UUID) {
        simulationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let waitTime = Double.random(in: 3...8)
                try? await Task.sleep(for: .seconds(waitTime))

                guard let self, self.activeChannel != nil, !Task.isCancelled else { break }
                guard !self.isSpeaking else { continue }

                let others = self.connectedParticipantIDs.filter { $0 != selfID }
                guard let speaker = others.randomElement() else { continue }

                self.currentSpeakerID = speaker
                self.currentSpeakerName = self.speakerNames[speaker] ?? "Rider"

                let speakDuration = Double.random(in: 1...3)
                try? await Task.sleep(for: .seconds(speakDuration))

                guard !Task.isCancelled else { break }
                if self.currentSpeakerID == speaker {
                    self.currentSpeakerID = nil
                    self.currentSpeakerName = nil
                }
            }
        }
    }
}
