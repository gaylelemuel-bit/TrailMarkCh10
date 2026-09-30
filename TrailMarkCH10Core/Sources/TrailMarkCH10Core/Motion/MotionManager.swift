import CoreMotion
import Foundation
import Observation

@MainActor
@Observable
public final class MotionManager {
    public enum Activity: String, Sendable {
        case stationary
        case walking
        case running
        case cycling
        case unknown

        public var label: String { rawValue.capitalized }

        public var symbolName: String {
            switch self {
            case .stationary: "figure.stand"
            case .walking: "figure.walk"
            case .running: "figure.run"
            case .cycling: "bicycle"
            case .unknown: "questionmark"
            }
        }
    }

    public private(set) var stepsToday = 0
    public private(set) var cadence = 0.0
    public private(set) var activity: Activity = .unknown
    public private(set) var acceleration: (Double, Double, Double) = (0, 0, 0)
    public private(set) var isUpdating = false
    public private(set) var lastErrorMessage: String?

    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()

    public init() {}

    public var isShakeDetected: Bool {
        accMagnitude >= 2.4
    }

    public var accMagnitude: Double {
        (
            acceleration.0 * acceleration.0
            + acceleration.1 * acceleration.1
            + acceleration.2 * acceleration.2
        ).squareRoot()
    }


    public static var isPedometerAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    public static var isPedometersAvailable: Bool {
        isPedometerAvailable
    }

    public static var isActivityAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    public static var isDeviceMotionAvailable: Bool {
        CMMotionManager().isDeviceMotionAvailable
    }


    public func startAllUpdates() {
        lastErrorMessage = nil
        isUpdating = true
        startActivityUpdate()
        startPedometer()
        startAccelerometerUpdates()

        if !Self.isPedometerAvailable && !Self.isActivityAvailable && !Self.isDeviceMotionAvailable {
            isUpdating = false
            lastErrorMessage = "Motion data is unavailable on this device."
        }
    }

    public func startActivityUpdate() {
        guard Self.isActivityAvailable else { return }

        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }

            let resolvedActivity: Activity

            if activity.walking {
                resolvedActivity = .walking
            } else if activity.running {
                resolvedActivity = .running
            } else if activity.cycling {
                resolvedActivity = .cycling
            } else if activity.stationary {
                resolvedActivity = .stationary
            } else {
                resolvedActivity = .unknown
            }

            self?.activity = resolvedActivity
        }
    }

    public func startAccelerometerUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error {
                self?.lastErrorMessage = error.localizedDescription
                return
            }

            guard let data = motion?.userAcceleration else { return }
            self?.acceleration = (data.x, data.y, data.z)
        }
    }

    public func startPedometer() {
        guard Self.isPedometerAvailable else { return }

        guard CMPedometer.authorizationStatus() != .denied else {
            lastErrorMessage = "Motion access is denied. Enable Motion & Fitness access in Settings."
            return
        }

        pedometer.startUpdates(from: Calendar.current.startOfDay(for: Date())) { [weak self] data, error in
            if let error {
                let message = error.localizedDescription
                Task { @MainActor in
                    self?.lastErrorMessage = message
                }
                return
            }

            guard let data else { return }
            let steps = data.numberOfSteps.intValue
            let cadence = (data.currentCadence?.doubleValue ?? 0) * 60

            Task { @MainActor in
                self?.stepsToday = steps
                self?.cadence = cadence
            }
        }
    }

    public func stopAllUpdates() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        motionManager.stopDeviceMotionUpdates()
        isUpdating = false
    }
}
