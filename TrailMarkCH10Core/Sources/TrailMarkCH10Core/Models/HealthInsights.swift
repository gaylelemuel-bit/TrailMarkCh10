import Foundation

public struct SleepSummary: Sendable, Equatable, Codable {
    public var asleepSeconds: TimeInterval
    public var date: Date

    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()) {
        self.asleepSeconds = asleepSeconds
        self.date = date
    }

    public static let empty = SleepSummary()


    public var hours: Double { asleepSeconds / 3600 }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: asleepSeconds) ?? "—"
    }
}

public struct EnergyTrendPoint: Sendable, Equatable, Codable, Identifiable {
    public var id: Date { day }
    public var day: Date
    public var activeEnergyKcal: Double

    public init(day: Date, activeEnergyKcal: Double) {
        self.day = day
        self.activeEnergyKcal = activeEnergyKcal
    }
}

public struct LiveVitals: Sendable, Equatable, Codable {
    public var heartRateBPM: Double
    public var steps: Double
    public var activeEnergyKcal: Double

    public init(heartRateBPM: Double = 0, steps: Double = 0, activeEnergyKcal: Double = 0) {
        self.heartRateBPM = heartRateBPM
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
    }

    public static let empty = LiveVitals()


    public var heartRateText: String {
        heartRateBPM > 0 ? "\(Int(heartRateBPM.rounded()))" : "—"
    }
}
