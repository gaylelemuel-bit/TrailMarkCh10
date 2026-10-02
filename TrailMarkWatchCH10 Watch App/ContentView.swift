import SwiftUI
import TrailMarkCH10Core

struct ContentView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                WristHomeView()

                Section("Explore") {
                    NavigationLink {
                        LiveWorkoutView()
                    } label: {
                        Label("Start Workout", systemImage: "figure.walk.circle.fill")
                    }

                    NavigationLink {
                        LiveVitalsView()
                    } label: {
                        Label("Live Vitals", systemImage: "heart.text.square.fill")
                    }

                    NavigationLink {
                        MotionView()
                    } label: {
                        Label("Motion", systemImage: "figure.run")
                    }

                    NavigationLink {
                        WristMemoView()
                    } label: {
                        Label("Voice Memos", systemImage: "mic.fill")
                    }

                    NavigationLink {
                        QuickLogView()
                    } label: {
                        Label("Quick Log", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("TrailMark")
            .refreshable {
                await refreshHealthData()
            }
            .task {
                await refreshHealthData()
            }
        }
    }

    private func refreshHealthData() async {
        if model.health.currentAuthStatus == .unknown {
            await model.health.requestAuthorization()
        }

        if model.health.currentAuthStatus == .authorized {
            await model.health.refreshTodaysSummary()
        }
    }
}

#Preview {
    ContentView()
        .environment(WatchModel())
}
