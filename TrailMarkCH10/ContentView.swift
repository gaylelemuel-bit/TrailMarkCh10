import SwiftUI
import TrailMarkCH10Core

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        TabView {
            TodayDashboardView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            JourneyListView()
                .tabItem {
                    Label("Journeys", systemImage: "map.fill")
                }

            FieldJournalView()
                .tabItem {
                    Label("Journal", systemImage: "waveform")
                }

            RecoveryView()
                .tabItem {
                    Label("Recovery", systemImage: "bed.double.fill")
                }
        }
        .task {
            await model.refreshHealthData()
        }
        .alert(item: $model.presentedError) { error in
            if let recoverySuggestion = error.recoverySuggestion {
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    primaryButton: .default(Text(recoverySuggestion)) {
                        Task {
                            await model.refreshHealthData()
                        }
                    },
                    secondaryButton: .cancel()
                )
            } else {
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
