//
//  TodayDashboardView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/8/26.
//

import SwiftUI
import Charts
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
                    healthAccessView(
                        title: "Health Access Needed",
                        systemImage: "heart.text.square",
                        message: "TrailMark needs permission to read activity and sleep, and to save sample workouts."
                    )
                case .denied:
                    healthAccessView(
                        title: "Health Access Denied",
                        systemImage: "lock.slash",
                        message: model.health.lastErrorMessage ?? "Open Settings and allow Health access to show activity, sleep, and sample workouts."
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

        return List {
            Section("Today") {
                MetricRow(title: "Steps", value: summary.stepsText, systemImage: "figure.walk")
                MetricRow(title: "Distance", value: summary.distanceText, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                MetricRow(title: "Active Energy", value: summary.activeEnergyText, systemImage: "flame")
                MetricRow(title: "Flights Climbed", value: summary.flightsClimbedText, systemImage: "stairs")
                MetricRow(title: "Exercise", value: summary.exerciseMinutesText, systemImage: "figure.run")
            }

            Section("Last Night") {
                MetricRow(title: "Sleep", value: model.health.lastNightSleepText, systemImage: "bed.double")
            }

            Section("Active Energy") {
                if model.health.activeEnergyHistory.isEmpty {
                    ContentUnavailableView(
                        "No Energy Data",
                        systemImage: "chart.bar",
                        description: Text("The last 7 days of active energy will appear here after Health has data to share.")
                    )
                } else {
                    Chart(model.health.activeEnergyHistory) { sample in
                        BarMark(
                            x: .value("Day", sample.date, unit: .day),
                            y: .value("Kilocalories", sample.kilocalories)
                        )
                    }
                    .frame(height: 180)
                }
            }

            Section("Health Write") {
                Button {
                    Task {
                        await model.health.saveSampleWorkout()
                    }
                } label: {
                    Label("Save Sample Hike", systemImage: "figure.hiking")
                }

                if let message = model.health.lastWorkoutSaveMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let message = model.health.lastErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func healthAccessView(title: String, systemImage: String, message: String) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(message)
            )

            Button {
                Task {
                    await model.health.requestAuthorization()
                }
            } label: {
                Label("Request Health Access", systemImage: "heart.text.square")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func refresh() async {
        if model.health.authorizationState == .undetermined {
            await model.health.requestAuthorization()
        } else {
            await model.health.refreshHealthData()
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
