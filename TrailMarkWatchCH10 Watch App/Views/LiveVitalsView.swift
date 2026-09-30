import SwiftUI
import TrailMarkCH10Core

struct LiveVitalsView: View {
    @Environment(WatchModel.self) private var model

    private var liveVitals: LiveVitals {
        model.health.liveVitals
    }

    var body: some View {
        List {
            switch model.health.currentAuthStatus {
            case .unknown, .requesting:
                Section {
                    HStack {
                        ProgressView()
                        Text("Preparing Health access…")
                            .foregroundStyle(.secondary)
                    }
                }

            case .unavailable:
                healthMessage(
                    "Health data isn’t available on this device.",
                    symbol: "heart.slash"
                )

            case .denied:
                healthMessage(
                    model.health.lastErrorMessage ?? "Health access is needed to show live vitals.",
                    symbol: "lock.fill"
                )

            case .authorized:
                vitalCard(
                    title: "Heart Rate",
                    value: liveVitals.heartRateText,
                    unit: "bpm",
                    symbol: "heart.fill",
                    tint: .red
                )
                vitalCard(
                    title: "Steps",
                    value: liveVitals.steps.formatted(.number.precision(.fractionLength(0))),
                    unit: "",
                    symbol: "figure.walk",
                    tint: .yellow
                )
                vitalCard(
                    title: "Active Energy",
                    value: liveVitals.activeEnergyKcal.formatted(.number.precision(.fractionLength(0))),
                    unit: "kcal",
                    symbol: "flame.fill",
                    tint: .orange
                )

                if let message = model.health.lastErrorMessage {
                    healthMessage(message, symbol: "exclamationmark.triangle.fill")
                }
            }
        }
        .navigationTitle("Live Vitals")
        .task {
            if model.health.currentAuthStatus == .unknown {
                await model.health.requestAuthorization()
            }

            if model.health.currentAuthStatus == .authorized {
                model.health.startLiveHeartUpdates()
            }
        }
        .onDisappear {
            model.health.stopLiveQueries()
        }
    }

    private func vitalCard(
        title: LocalizedStringKey,
        value: String,
        unit: String,
        symbol: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .monospacedDigit()

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func healthMessage(_ message: String, symbol: String) -> some View {
        Section {
            Label(message, systemImage: symbol)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
