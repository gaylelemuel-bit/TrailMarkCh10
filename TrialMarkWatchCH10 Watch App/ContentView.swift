//
//  ContentView.swift
//  TrialMarkWatchCH10 Watch App
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import TrialMarkCH10Core

struct ContentView: View {
    @Environment(WatchAppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today")
                    .font(.headline)

                switch model.health.authorizationState {
                case .authorized:
                    if model.health.todaysSummary.hasData {
                        MetricLabel(title: "Steps", value: model.health.todaysSummary.stepsText)
                        MetricLabel(title: "Distance", value: model.health.todaysSummary.distanceText)
                        MetricLabel(title: "Energy", value: model.health.todaysSummary.activeEnergyText)
                        MetricLabel(title: "Flights", value: model.health.todaysSummary.flightsClimbedText)
                        MetricLabel(title: "Exercise", value: model.health.todaysSummary.exerciseMinutesText)
                    } else {
                        EmptyStateText("No activity recorded yet.")
                    }
                case .requesting:
                    ProgressView()
                case .undetermined:
                    EmptyStateText("Health access is needed.")
                case .denied:
                    EmptyStateText(model.health.lastErrorMessage ?? "Health access is denied.")
                case .unavailable:
                    EmptyStateText("Health data is unavailable.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .task {
            await refresh()
        }
    }

    private func refresh() async {
        if model.health.authorizationState == .undetermined {
            await model.health.requestAuthorization()
        } else {
            await model.health.refreshTodaysSummary()
        }
    }
}

private struct MetricLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .monospacedDigit()
        }
    }
}

private struct EmptyStateText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
        .environment(WatchAppModel())
}
