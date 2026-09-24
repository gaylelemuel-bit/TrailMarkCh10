//
//  WristHomeView.swift
//  TrialMarkWatchCH10 Watch App
//

import SwiftUI
import TrialMarkCH10Core

/// The glanceable landing page: one headline metric and one quick action.
struct WristHomeView: View {
    @Environment(WatchAppModel.self) private var model
    @State private var isRecordingMemo = false

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            switch model.health.authorizationState {
            case .authorized:
                VStack(spacing: 2) {
                    Text(model.health.todaysSummary.stepsText)
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("steps today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            case .requesting:
                ProgressView()
            case .undetermined, .denied, .unavailable:
                Text("Health access is needed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                isRecordingMemo = true
            } label: {
                Label("Record Memo", systemImage: "mic.fill")
                    .font(.footnote)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal)
        .sheet(isPresented: $isRecordingMemo) {
            RecordMemoSheet()
        }
        .task {
            if model.health.authorizationState == .undetermined {
                await model.health.requestAuthorization()
            } else {
                await model.health.refreshTodaysSummary()
            }
        }
    }
}

#Preview {
    WristHomeView()
        .environment(WatchAppModel())
}
