import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {

    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable
        case requesting
        case authorized
        case denied
    }

    public private(set) var currentAuthStatus: AuthorizationState = .unknown

    public private(set) var todaysSummary: ActivitySummary = .empty

    public private(set) var sleep: SleepSummary = .empty

    public private(set) var energyTrend: [EnergyTrendPoint] = []

    public private(set) var liveVitals: LiveVitals = .empty
    public private(set) var isRefreshing = false
    public private(set) var lastErrorMessage: String?

    private let store = HKHealthStore()
    private var openLiveQueries: [HKQuery] = []

    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            currentAuthStatus = .unavailable
        }
    }


    private var stepsType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }
    private var heartRateType: HKQuantityType { HKQuantityType(.heartRate) }

    private var readTypes: Set<HKObjectType> {
        [stepsType, distanceType, energyType, sleepType, heartRateType]
    }

    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }

    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            currentAuthStatus = .unavailable
            lastErrorMessage = "Health data is unavailable on this device."
            return
        }

        currentAuthStatus = .requesting
        lastErrorMessage = nil

        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            currentAuthStatus = .authorized
        } catch {
            currentAuthStatus = .denied
            lastErrorMessage = error.localizedDescription
        }
    }

    public func refreshTodaysSummary() async {
        guard currentAuthStatus == .authorized else { return }

        isRefreshing = true
        lastErrorMessage = nil
        defer { isRefreshing = false }

        let startOfDay = Calendar.current.startOfDay(for: Date())

        do {
            async let steps = sumQuantity(stepsType, unit: .count(), since: startOfDay)
            async let distance = sumQuantity(distanceType, unit: .meter(), since: startOfDay)
            async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)

            todaysSummary = try await ActivitySummary(
                steps: steps,
                distanceMeteres: distance,
                activeEnergyKcal: energy,
                date: startOfDay
            )
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func sumQuantity(
        _ type: HKQuantityType,
        unit: HKUnit,
        since start: Date
    ) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let timePredicate = HKQuery.predicateForSamples(withStart: start, end: Date())

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: timePredicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            store.execute(query)
        }
    }


    public func refreshLastNightSleep() async {
        let calendar = Calendar.current
        let now = Date()

        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let sixPMYesterday = calendar.date(byAdding: .hour, value: -18, to: noonToday) ?? now

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let timePredicate = HKQuery.predicateForSamples(withStart: sixPMYesterday, end: noonToday)

            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: timePredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }

            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        let totalAsleep = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        sleep = SleepSummary(asleepSeconds: totalAsleep, date: calendar.startOfDay(for: now))
    }


    public func refreshEnergyTrend() async {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: Date())

        guard let startDay = calendar.date(byAdding: .day, value: -6, to: endDay) else { return }

        let trend: [EnergyTrendPoint] = await withCheckedContinuation { continuation in
            var interval = DateComponents()
            interval.day = 1

            let timePredicate = HKQuery.predicateForSamples(withStart: startDay, end: Date())

            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: timePredicate,
                options: .cumulativeSum,
                anchorDate: startDay,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, _ in
                var points: [EnergyTrendPoint] = []

                collection?.enumerateStatistics(from: startDay, to: Date()) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    points.append(EnergyTrendPoint(day: stats.startDate, activeEnergyKcal: kcal))
                }

                continuation.resume(returning: points)
            }

            store.execute(query)
        }

        energyTrend = trend
    }


    public func save(_ record: WorkoutRecord, activity: HKWorkoutActivityType = .walking) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        try await builder.beginCollection(at: record.start)

        var samples: [HKSample] = []

        if record.activeEnergyKcal > 0 {
            samples.append(
                HKCumulativeQuantitySample(
                    type: energyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: record.activeEnergyKcal),
                    start: record.start,
                    end: record.end
                )
            )
        }

        if record.distanceMeters > 0 {
            samples.append(
                HKCumulativeQuantitySample(
                    type: distanceType,
                    quantity: HKQuantity(unit: .meter(), doubleValue: record.distanceMeters),
                    start: record.start,
                    end: record.end
                )
            )
        }

        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: record.end)
        _ = try await builder.finishWorkout()
    }

    public func startLiveHeartUpdates() {
        guard currentAuthStatus == .authorized, openLiveQueries.isEmpty else { return }
        streamHeartRateData()
        Task {
            await refreshTodayVitals()
        }
    }

    public func refreshTodayVitals() async {
        guard currentAuthStatus == .authorized else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())

        do {
            async let steps = sumQuantity(stepsType, unit: .count(), since: startOfDay)
            async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)

            liveVitals.steps = try await steps
            liveVitals.activeEnergyKcal = try await energy
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func streamHeartRateData() {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: nil
        )

        let dataHandler: @Sendable (
            HKAnchoredObjectQuery,
            [HKSample]?,
            [HKDeletedObject]?,
            HKQueryAnchor?,
            Error?
        ) -> Void = { [weak self] _, samples, _,_,_ in
            guard let latest = (samples as? [HKQuantitySample])?.last else { return }
            let bpm = latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

            Task { @MainActor in
                self?.liveVitals.heartRateBPM = bpm
            }
        }

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: dataHandler
        )
        query.updateHandler = dataHandler

        store.execute(query)

        openLiveQueries.append(query)
    }

    public func stopLiveQueries() {
        openLiveQueries.forEach { store.stop($0) }
        openLiveQueries.removeAll()
    }

}
