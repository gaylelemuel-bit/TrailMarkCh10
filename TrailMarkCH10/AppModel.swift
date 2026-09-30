import Foundation
import Observation
import TrailMarkCH10Core

@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let location = LocationManager()
    let journeyStore = JourneyStore()
    let connectivity = ConnectivityManager.shared

    var presentedError: AppError?
    private(set) var lastHealthRefresh: Date?

    init() {
        wireConnectivity()
    }

    private func wireConnectivity() {
        connectivity.onReceiveJourney = { [weak self] journey in
            self?.journeyStore.add(journey)
        }
        connectivity.onReceiveWorkout = { [weak self] workout in
            let journey = Journey(
                title: "Watch activity",
                startedAt: workout.start,
                endedAt: workout.end,
                workout: workout
            )
            self?.journeyStore.add(journey)
        }
        connectivity.onReceiveMediaFile = { [weak self] tempURL, memo in
            guard let self else { return }
            let destination = self.media.mediaDirectory.appendingPathComponent(memo.fileName)
            try? FileManager.default.removeItem(at: destination)

            do {
                try FileManager.default.moveItem(at: tempURL, to: destination)
                self.media.register(memo)
            } catch {
                self.presentedError = .mediaImport(error.localizedDescription)
            }
        }
        connectivity.activate()
    }

    func refreshHealthData() async {
        presentedError = nil

        if health.currentAuthStatus == .unknown {
            await health.requestAuthorization()
        }

        switch health.currentAuthStatus {
        case .authorized:
            await health.refreshTodaysSummary()

            if let message = health.lastErrorMessage {
                presentedError = .healthRefresh(message)
            } else {
                lastHealthRefresh = Date()
                mirrorTodayToWatch()
            }

        case .denied:
            presentedError = .healthAuthorization

        case .unavailable:
            presentedError = .healthUnavailable

        case .unknown, .requesting:
            break
        }
    }

    func dismissError() {
        presentedError = nil
    }

    func mirrorTodayToWatch() {
        connectivity.sync(summary: health.todaysSummary)
    }
}
