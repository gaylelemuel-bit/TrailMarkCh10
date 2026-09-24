//
//  MotionView.swift
//  TrialMarkWatchCH10 Watch App
//

import SwiftUI
import TrialMarkCH10Core

/// A live pedometer session driven by the shared MotionManager. Sampling only
/// runs while the user has an active session to keep sensor cost down.
struct MotionView: View {
    @Environment(WatchAppModel.self) private var model

    var body: some View {
        VStack(spacing: 10) {
            if let message = model.motion.lastErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 2) {
                    Text(model.motion.stepsText)
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    Text(model.motion.isUpdating ? "steps this session" : "Start a session")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if model.motion.isUpdating {
                    HStack {
                        motionCell(title: "Distance", value: model.motion.distanceText)
                        Spacer()
                        motionCell(title: "Cadence", value: model.motion.cadenceText)
                    }
                }
            }

            Button(model.motion.isUpdating ? "Stop" : "Start") {
                if model.motion.isUpdating {
                    model.motion.stop()
                } else {
                    model.motion.start()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(model.motion.isUpdating ? .red : .green)
        }
        .padding(.horizontal)
        .navigationTitle("Motion")
        .onDisappear {
            model.motion.stop()
        }
    }

    private func motionCell(title: String, value: String) -> some View {
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
    MotionView()
        .environment(WatchAppModel())
}
