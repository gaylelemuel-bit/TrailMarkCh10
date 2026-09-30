import SwiftUI
import TrailMarkCH10Core

struct WristHomeView: View {
    @Environment(WatchModel.self) private var model

    private var summary: ActivitySummary {
        model.health.todaysSummary
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Steps Today", systemImage: "figure.walk")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if model.health.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }

                Text(summary.stepsText)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text(summary.distanceText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .listRowBackground(Color.clear)
        }

        if let message = model.health.lastErrorMessage {
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)

                Button("Try Again", systemImage: "arrow.clockwise") {
                    Task {
                        await model.health.requestAuthorization()
                        await model.health.refreshTodaysSummary()
                    }
                }
            }
        } else if model.health.currentAuthStatus == .unavailable {
            Section {
                Label("Health data is unavailable on this device.", systemImage: "heart.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        Section("From iPhone") {
            if let mirrored = model.connectivity.mirroredSummary {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(mirrored.stepsText) steps", systemImage: "iphone")
                        .font(.headline)
                    Text(mirrored.distanceText)
                        .font(.footnote)
                    Text("Updated \(mirrored.date, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else {
                Label("Open TrailMark on your iPhone to sync today’s activity.", systemImage: "iphone.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
