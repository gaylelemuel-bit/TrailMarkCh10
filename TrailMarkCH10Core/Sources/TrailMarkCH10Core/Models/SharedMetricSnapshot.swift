import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

public struct SharedMetricSnapshot: Codable, Sendable, Equatable {
    public let steps: Double
    public let distanceMeters: Double
    public let activeEnergyKcal: Double
    public let updatedAt: Date

    public init(
        steps: Double,
        distanceMeters: Double,
        activeEnergyKcal: Double,
        updatedAt: Date
    ) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergyKcal = activeEnergyKcal
        self.updatedAt = updatedAt
    }

    public init(summary: ActivitySummary) {
        self.init(
            steps: summary.steps,
            distanceMeters: summary.distanceMeters,
            activeEnergyKcal: summary.activeEnergyKcal,
            updatedAt: summary.date
        )
    }

    public static let empty = SharedMetricSnapshot(
        steps: 0,
        distanceMeters: 0,
        activeEnergyKcal: 0,
        updatedAt: .distantPast
    )
}

public enum SharedMetricStore {
    public static let appGroupIdentifier = "group.ramsesg.TrailMarkCH10.shared"
    public static let widgetKind = "TrailMarkMetricWidget"

    private static let snapshotKey = "sharedMetricSnapshot"

    public static func save(_ snapshot: SharedMetricSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: snapshotKey)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        #endif
    }

    public static func load() -> SharedMetricSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedMetricSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }
}
