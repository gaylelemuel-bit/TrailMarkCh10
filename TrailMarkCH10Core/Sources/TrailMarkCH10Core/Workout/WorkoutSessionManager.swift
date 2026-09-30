#if os(WatchOS)
import Foundation
import Combine
import HealthKit
import Observation

@MainActor
@Observable
final class WorkoutSessionManager: NSObject {

    public private(set) var isRunning: Bool = false

    public private(set) var heartRate: Double = 0.0
    public private(set) var activeEnergy: Double = 0.0
    public private(set) var distanceMeters: Double = 0.0
    public private(set) var startDate: Date?

    public var onFinish: ((WorkoutRecord) -> Void)?

    private let store = HKHealthStore()
    private let session: HKWorkoutSession?
    private let builder: HKWorkoutBuilder?

    public override init() { super.init() }

    public var elapsed: TimeInterval {
        guard let startDate else { return }
        return Date().timeIntervalSince(startDate)
    }


    public func start() {
        guard !isRunning else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store)

            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder

            let now = Date()

            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { [weak self] _, error in
                Task { @MainActor in
                    self?.isRunning = true
                    self?.startDate = now
                }
            }
        }
        catch {
            isRunning = false
        }
    }

    public func end() {
        guard let session, let builder else { return }
        let endDate = Date()
        session.end()
        builder.endCollection(withEnd: endDate) { [weak self] _,_ in
            builder.finishWorkout() {_,_ in
                Task { @MainActor in self?.finalize(end: endDate) }
            }
        }
    }

    public func finalize(end: Date) {
        let record = WorkoutRecord(
            start: startDate ?? end,
            end: end,
            activeEnergyKcal: activeEnergy,
            distanceMeters: distanceMeters,
            averageHeartRate: heartRate > 0 ? heartRate : nil
        )
        isRunning = false
        onFinish?(record)
        session = nil
        builder = nil
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(
        _ session: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor in self?.isRunning = false }
    }

    nonisolated public func workoutSession(
        _ session: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            self.isRunning = toState == .running
        }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    nonisolated public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { return }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0.0
                Task { @MainActor in self?.heartRate = bpm }

            case HKQuantityType(.activeEnergyBurned):
                let kcal = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                Task { @MainActor in self?.activeEnergy = kcal }

            case HKQuantityType(.distanceWalkingRunning):
                let distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                Task { @MainActor in self?.distanceMeters = distance }

            default:
                break
            }
        }
    }
}

#endif
