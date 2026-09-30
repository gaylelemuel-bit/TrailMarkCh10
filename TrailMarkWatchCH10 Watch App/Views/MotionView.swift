import SwiftUI
import TrailMarkCH10Core

struct MotionView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        List {
            Section("Current Activity") {
                HStack(spacing: 12) {
                    Image(systemName: model.motion.activity.symbolName)
                        .font(.title2)
                        .foregroundStyle(.teal)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.motion.activity.label)
                            .font(.headline)
                        Text(model.motion.isUpdating ? "Live" : "Paused")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            Section("Today") {
                LabeledContent(
                    "Cadence",
                    value: "\(model.motion.cadence.formatted(.number.precision(.fractionLength(0)))) spm"
                )
                LabeledContent("Steps", value: model.motion.stepsToday.formatted())
                LabeledContent(
                    "Acceleration",
                    value: model.motion.accMagnitude.formatted(.number.precision(.fractionLength(2)))
                )

                if model.motion.isShakeDetected {
                    Label("Shake detected", systemImage: "waveform.path")
                        .foregroundStyle(.orange)
                }
            }

            if let message = model.motion.lastErrorMessage {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Motion")
        .onAppear {
            model.motion.startAllUpdates()
        }
        .onDisappear {
            model.motion.stopAllUpdates()
        }
    }
}
