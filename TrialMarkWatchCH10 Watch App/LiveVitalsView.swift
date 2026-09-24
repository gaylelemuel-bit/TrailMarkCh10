//
//  LiveVitalsView.swift
//  TrialMarkWatchCH10 Watch App
//

import SwiftUI
import TrialMarkCH10Core

/// Live heart rate, steps, and active energy streamed through the shared
/// HealthKitManager. Streaming starts when the page appears and stops when it
/// disappears to avoid unnecessary sensor cost.
struct LiveVitalsView: View {
    @Environment(WatchAppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.health.authorizationState == .authorized {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        Text(model.health.liveVitals.heartRateText)
                            .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    Text("BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    vitalsCell(title: "Steps", value: model.health.liveVitals.stepsText)
                    Spacer()
                    vitalsCell(title: "Energy", value: model.health.liveVitals.activeEnergyText)
                }
            } else {
                Text("Health access is needed for live vitals.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal)
        .navigationTitle("Vitals")
        .task {
            if model.health.authorizationState == .undetermined {
                await model.health.requestAuthorization()
            }
            model.health.startLiveVitals()
        }
        .onDisappear {
            model.health.stopLiveVitals()
        }
    }

    private func vitalsCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .monospacedDigit()
        }
    }
}

#Preview {
    LiveVitalsView()
        .environment(WatchAppModel())
}
