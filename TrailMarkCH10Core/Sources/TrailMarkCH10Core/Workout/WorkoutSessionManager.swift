#if os(watchOS)
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class WorkoutSessionManager: NSObject {
    public enum State: Sendable {
        case idle
        case starting
        case running
        case paused
        case finishing
        case failed
    }

    public private(set) var state: State = .idle
    public private(set) var heartRate = 0.0
    public private(set) var activeEnergy = 0.0
    public private(set) var distanceMeters = 0.0
    public private(set) var startDate: Date?
    public private(set) var lastErrorMessage: String?

    public var onFinish: ((WorkoutRecord) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    public override init() {
        super.init()
    }

    public var isActive: Bool {
        state == .running || state == .paused
    }

    public var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }

    public func start() async {
        guard state == .idle || state == .failed else { return }

        state = .starting
        lastErrorMessage = nil
        heartRate = 0
        activeEnergy = 0
        distanceMeters = 0

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(
                healthStore: store,
                configuration: configuration
            )
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: store,
                workoutConfiguration: configuration
            )
            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder

            let startDate = Date()
            self.startDate = startDate
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
            state = .running
        } catch {
            fail(with: error)
        }
    }

    public func pause() {
        guard state == .running else { return }
        session?.pause()
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        session?.resume()
        state = .running
    }

    @discardableResult
    public func end() async -> WorkoutRecord? {
        guard isActive, let session, let builder else { return nil }

        state = .finishing
        let endDate = Date()
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()

            let record = WorkoutRecord(
                start: startDate ?? endDate,
                end: endDate,
                activeEnergyKcal: activeEnergy,
                distanceMeters: distanceMeters,
                averageHeartRate: heartRate > 0 ? heartRate : nil
            )

            reset()
            onFinish?(record)
            return record
        } catch {
            fail(with: error)
            return nil
        }
    }

    public func discard() async {
        guard let session, let builder else {
            reset()
            return
        }

        session.end()
        builder.discardWorkout()
        reset()
    }

    private func reset() {
        session = nil
        builder = nil
        startDate = nil
        state = .idle
    }

    private func fail(with error: Error) {
        lastErrorMessage = error.localizedDescription
        session = nil
        builder = nil
        startDate = nil
        state = .failed
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.fail(with: error)
        }
    }

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            switch toState {
            case .running:
                self.state = .running
            case .paused:
                self.state = .paused
            case .ended:
                if self.state != .finishing {
                    self.reset()
                }
            default:
                break
            }
        }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {}

    nonisolated public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                Task { @MainActor [weak self] in
                    self?.heartRate = value
                }

            case HKQuantityType(.activeEnergyBurned):
                let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor [weak self] in
                    self?.activeEnergy = value
                }

            case HKQuantityType(.distanceWalkingRunning):
                let value = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                Task { @MainActor [weak self] in
                    self?.distanceMeters = value
                }

            default:
                break
            }
        }
    }
}
#endif
