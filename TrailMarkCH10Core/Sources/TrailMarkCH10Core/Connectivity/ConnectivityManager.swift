import Foundation
import Observation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
@Observable
public final class ConnectivityManager: NSObject {

    public static let shared = ConnectivityManager()

    public private(set) var isReachable = false
    public private(set) var isActivated = false
    public private(set) var lastError: String?

    public private(set) var mirroredSummary: ActivitySummary?


    public private(set) var pendingMemoIDs: Set<UUID> = []
    public private(set) var failedMemoIDs: Set<UUID> = []
    public private(set) var pendingRecordCount = 0

    public var onReceiveWorkout: ((WorkoutRecord) -> Void)?
    public var onReceiveJourney: ((Journey) -> Void)?
    public var onReceiveMediaFile: ((URL, MediaMemo) -> Void)?

    private enum PayloadType: String {
        case summary, workout, journey, memo
    }

    #if canImport(WatchConnectivity)
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }
    #endif

    public func activate() {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        session.delegate = self
        session.activate()
        #endif
    }


    private var canSend: Bool {
        #if canImport(WatchConnectivity)
        guard let session, session.activationState == .activated else { return false }
        #if os(iOS)
        return session.isPaired && session.isWatchAppInstalled
        #else
        return true
        #endif
        #else
        return false
        #endif
    }

    public func sync(summary: ActivitySummary) {
        #if canImport(WatchConnectivity)
        guard canSend, let data = try? JSONEncoder().encode(summary) else { return }
        try? session?.updateApplicationContext([
            "type": PayloadType.summary.rawValue,
            "payload": data
        ])
        #endif
    }

    public func sync(workout: WorkoutRecord) {
        send(.workout, encoding: workout)
    }

    public func sync(journey: Journey) {
        send(.journey, encoding: journey)
    }

    public func transfer(memo: MediaMemo, fileURL: URL) {
        #if canImport(WatchConnectivity)
        guard canSend else {
            failedMemoIDs.insert(memo.id)
            lastError = "Counterpart not available — memo not sent"
            return
        }
        guard let data = try? JSONEncoder().encode(memo),
              let json = String(data: data, encoding: .utf8) else { return }
        session?.transferFile(fileURL, metadata: [
            "type": PayloadType.memo.rawValue,
            "memo": json,
            "memoID": memo.id.uuidString
        ])
        failedMemoIDs.remove(memo.id)
        pendingMemoIDs.insert(memo.id)
        #endif
    }

    private func send<T: Encodable>(_ type: PayloadType, encoding value: T) {
        #if canImport(WatchConnectivity)
        guard canSend, let data = try? JSONEncoder().encode(value) else { return }
        session?.transferUserInfo([
            "type": type.rawValue,
            "payload": data
        ])
        pendingRecordCount += 1
        #endif
    }

    #if canImport(WatchConnectivity)
    nonisolated private static func outstandingMemoIDs(in session: WCSession) -> Set<UUID> {
        Set(session.outstandingFileTransfers.compactMap {
            ($0.file.metadata?["memoID"] as? String).flatMap(UUID.init(uuidString:))
        })
    }
    #endif
}

#if canImport(WatchConnectivity)
extension ConnectivityManager: WCSessionDelegate {


    nonisolated public func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        let message = error?.localizedDescription
        let pendingMemos = Self.outstandingMemoIDs(in: session)
        let pendingRecords = session.outstandingUserInfoTransfers.count
        Task { @MainActor in
            self.isActivated = (state == .activated)
            self.lastError = message
            self.pendingMemoIDs = pendingMemos
            self.pendingRecordCount = pendingRecords
        }
    }

    nonisolated public func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: Error?
    ) {
        let memoID = (fileTransfer.file.metadata?["memoID"] as? String).flatMap(UUID.init(uuidString:))
        let message = error?.localizedDescription
        Task { @MainActor in
            guard let memoID else { return }
            self.pendingMemoIDs.remove(memoID)
            if let message {
                self.failedMemoIDs.insert(memoID)
                self.lastError = message
            }
        }
    }

    nonisolated public func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: Error?
    ) {
        let message = error?.localizedDescription
        Task { @MainActor in
            self.pendingRecordCount = max(0, self.pendingRecordCount - 1)
            if let message { self.lastError = message }
        }
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.isReachable = reachable }
    }

    nonisolated public func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        handle(dictionary: applicationContext)
    }

    nonisolated public func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        handle(dictionary: userInfo)
    }

    nonisolated public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let metadata = file.metadata ?? [:]
        let type = metadata["type"] as? String
        let json = metadata["memo"] as? String

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: tempURL)
        do {
            try FileManager.default.copyItem(at: file.fileURL, to: tempURL)
        } catch {
            let message = error.localizedDescription
            Task { @MainActor in self.lastError = message }
            return
        }

        Task { @MainActor in
            guard type == PayloadType.memo.rawValue,
                  let data = json?.data(using: .utf8),
                  let memo = try? JSONDecoder().decode(MediaMemo.self, from: data) else { return }
            self.onReceiveMediaFile?(tempURL, memo)
        }
    }

    private nonisolated func handle(dictionary: [String: Any]) {
        guard let typeString = dictionary["type"] as? String,
              let type = PayloadType(rawValue: typeString),
              let data = dictionary["payload"] as? Data else { return }
        Task { @MainActor in
            switch type {
            case .summary:
                if let summary = try? JSONDecoder().decode(ActivitySummary.self, from: data) {
                    self.mirroredSummary = summary
                    SharedMetricStore.save(SharedMetricSnapshot(summary: summary))
                }
            case .workout:
                if let workout = try? JSONDecoder().decode(WorkoutRecord.self, from: data) {
                    self.onReceiveWorkout?(workout)
                }
            case .journey:
                if let journey = try? JSONDecoder().decode(Journey.self, from: data) {
                    self.onReceiveJourney?(journey)
                }
            case .memo:
                break
            }
        }
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
#endif
