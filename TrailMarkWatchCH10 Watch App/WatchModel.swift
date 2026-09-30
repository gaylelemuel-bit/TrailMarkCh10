import Foundation
import Observation
import TrailMarkCH10Core

@MainActor
@Observable
final class WatchModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let motion = MotionManager()
    let connectivity = ConnectivityManager.shared

    init() {
        connectivity.activate()
    }

    @discardableResult
    func saveAndSync(memoFrom url: URL, duration: TimeInterval) throws -> MediaMemo {
        let memo = try media.add(kind: .audio, movingFileFrom: url, duration: duration)
        connectivity.transfer(memo: memo, fileURL: media.url(for: memo))
        return memo
    }

    func resend(_ memo: MediaMemo) {
        connectivity.transfer(memo: memo, fileURL: media.url(for: memo))
    }

    func syncFinished(workout record: WorkoutRecord) {
        connectivity.sync(workout: record)
    }
}
