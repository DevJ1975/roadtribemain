//
//  VoiceChannelOverlay.swift
//  Road Tribe
//
//  Top-floating banner shown whenever the rider is in a voice channel.
//  Displays current speaker, mic level meter, and a mute toggle.
//

import SwiftUI

struct VoiceChannelOverlay: View {
    @Environment(VoiceChannelService.self) private var voice

    var body: some View {
        if voice.isInChannel {
            content
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: voice.isInChannel)
        }
    }

    private var content: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            speakerIndicator
            VStack(alignment: .leading, spacing: 0) {
                Text(speakerLine)
                    .font(.rtCaptionBold)
                    .lineLimit(1)
                Text("\(voice.connectedParticipantIDs.count) on channel")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            micLevelMeter
            muteButton
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var speakerLine: String {
        if let name = voice.currentSpeakerName, voice.isSpeaking || voice.currentSpeakerID != nil {
            return "🎙️ \(name)"
        }
        return "Voice channel"
    }

    private var speakerIndicator: some View {
        ZStack {
            Circle()
                .fill(voice.currentSpeakerID == nil
                      ? Color.secondary.opacity(0.3)
                      : DesignSystem.Colors.brand.opacity(0.25))
                .frame(width: 28, height: 28)
            Image(systemName: voice.currentSpeakerID == nil ? "person.wave.2" : "waveform")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(voice.currentSpeakerID == nil
                                 ? Color.secondary
                                 : DesignSystem.Colors.brand)
                .symbolEffect(.variableColor.iterative, isActive: voice.currentSpeakerID != nil)
        }
    }

    private var micLevelMeter: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                let threshold = Float(i + 1) * 0.25
                Capsule()
                    .fill(voice.micLevel >= threshold
                          ? DesignSystem.Colors.success
                          : Color.secondary.opacity(0.25))
                    .frame(width: 3, height: CGFloat(6 + i * 3))
            }
        }
        .opacity(voice.isMuted ? 0.3 : 1)
    }

    private var muteButton: some View {
        Button {
            voice.toggleMute()
        } label: {
            Image(systemName: voice.isMuted ? "mic.slash.fill" : "mic.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(voice.isMuted ? DesignSystem.Colors.danger : .primary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.thinMaterial))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(voice.isMuted ? "Unmute" : "Mute")
    }
}
