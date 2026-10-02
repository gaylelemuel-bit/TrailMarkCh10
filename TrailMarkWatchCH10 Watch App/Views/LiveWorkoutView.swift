import SwiftUI
import TrailMarkCH10Core

struct LiveWorkoutView: View {
    @Environment(WatchModel.self) private var model
    @State private var isConfirmingEnd = false

    var body: some View {
        List {
            Section {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(elapsedText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())
                }
            }
            .listRowBackground(Color.clear)

            Section("Live Metrics") {
                metricRow(
                    "Heart Rate",
                    value: model.workout.heartRate.formatted(.number.precision(.fractionLength(0))),
                    unit: "bpm",
                    symbol: "heart.fill",
                    tint: .red
                )
                metricRow(
                    "Energy",
                    value: model.workout.activeEnergy.formatted(.number.precision(.fractionLength(0))),
                    unit: "kcal",
                    symbol: "flame.fill",
                    tint: .orange
                )
                metricRow(
                    "Distance",
                    value: Measurement(
                        value: model.workout.distanceMeters,
                        unit: UnitLength.meters
                    ).formatted(.measurement(width: .abbreviated, usage: .road)),
                    unit: "",
                    symbol: "location.fill",
                    tint: .teal
                )
            }

            if let error = model.workout.lastErrorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                controls
            }
        }
        .navigationTitle("Workout")
        .task {
            if model.health.currentAuthStatus == .unknown {
                await model.health.requestAuthorization()
            }
        }
        .confirmationDialog(
            "Finish this workout?",
            isPresented: $isConfirmingEnd,
            titleVisibility: .visible
        ) {
            Button("Finish Workout") {
                Task {
                    await model.workout.end()
                }
            }
            Button("Discard Workout", role: .destructive) {
                Task {
                    await model.workout.discard()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch model.workout.state {
        case .idle, .failed:
            Button {
                Task {
                    await model.workout.start()
                }
            } label: {
                Label("Start Walk", systemImage: "figure.walk.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

        case .starting, .finishing:
            HStack {
                ProgressView()
                Text(model.workout.state == .starting ? "Starting…" : "Saving…")
            }
            .frame(maxWidth: .infinity)

        case .running:
            Button("Pause", systemImage: "pause.fill") {
                model.workout.pause()
            }

            Button("Finish", systemImage: "stop.fill", role: .destructive) {
                isConfirmingEnd = true
            }

        case .paused:
            Button("Resume", systemImage: "play.fill") {
                model.workout.resume()
            }

            Button("Finish", systemImage: "stop.fill", role: .destructive) {
                isConfirmingEnd = true
            }
        }
    }

    private func metricRow(
        _ title: LocalizedStringKey,
        value: String,
        unit: String,
        symbol: String,
        tint: Color
    ) -> some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(value)
                .monospacedDigit()

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var elapsedText: String {
        Duration.seconds(model.workout.elapsed)
            .formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NavigationStack {
        LiveWorkoutView()
            .environment(WatchModel())
    }
}
