//
//  TodayDashboardView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import TrialMarkCH10Core

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                switch model.health.authorizationState {
                case .authorized:
                    dashboardContent
                case .requesting:
                    ProgressView("Requesting Health access...")
                case .undetermined:
                    ContentUnavailableView(
                        "Health Access Needed",
                        systemImage: "heart.text.square",
                        description: Text("TrailMark needs permission to read today's steps, walking distance, and active energy.")
                    )
                case .denied:
                    ContentUnavailableView(
                        "Health Access Denied",
                        systemImage: "lock.slash",
                        description: Text(model.health.lastErrorMessage ?? "Open Settings and allow Health access to show today's activity.")
                    )
                case .unavailable:
                    ContentUnavailableView(
                        "Health Data Unavailable",
                        systemImage: "heart.slash",
                        description: Text("Health data is not available on this device.")
                    )
                }
            }
            .navigationTitle("Today")
            .task {
                await refresh()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    private var dashboardContent: some View {
        let summary = model.health.todaysSummary

        return Group {
            if summary.hasData {
                List {
                    Section {
                        MetricRow(title: "Steps", value: summary.stepsText, systemImage: "figure.walk")
                        MetricRow(title: "Distance", value: summary.distanceText, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        MetricRow(title: "Active Energy", value: summary.activeEnergyText, systemImage: "flame")
                        MetricRow(title: "Flights Climbed", value: summary.flightsClimbedText, systemImage: "stairs")
                        MetricRow(title: "Exercise", value: summary.exerciseMinutesText, systemImage: "figure.run")
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView(
                    "No Activity Yet",
                    systemImage: "figure.walk.motion",
                    description: Text("Today's Health totals will appear here after your device records activity.")
                )
            }
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

private struct MetricRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    TodayDashboardView()
        .environment(AppModel())
}
