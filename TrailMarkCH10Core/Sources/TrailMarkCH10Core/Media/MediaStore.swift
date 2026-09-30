import Foundation
import AVFoundation
import CoreLocation
import Observation

@MainActor
@Observable
public final class MediaStore {
    public private(set) var memos: [MediaMemo] = []

    private let fileManager = FileManager.default
    private let indexFileName = "memos.json"

    public init() {
        loadIndexData()
    }


    public var mediaDirectory: URL {
        let base = fileManager.urls(for: .applicationDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Media", isDirectory: true)

        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    private var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }

    public func url(for memo: MediaMemo) -> URL {
        mediaDirectory.appendingPathComponent(memo.fileName)
    }

    @discardableResult
    public func add(
        kind: MemoKind,
        movingFileFrom sourceURL: URL,
        duration: TimeInterval,
        title: String = "",
        coordinate: CLLocationCoordinate2D? = nil
    ) throws -> MediaMemo {
        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? (kind == .audio ? "m4a" : "mov") : sourceURL.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = mediaDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }

        try? fileManager.moveItem(at: sourceURL, to: destination)

        var memo = MediaMemo(
            id: id,
            kind: kind,
            fileName: fileName,
            duration: duration,
            title: title
        )

        memo.setCoordinate(coordinate)

        memos.insert(memo, at: 0)
        persistIndex()
        return memo
    }

    public func register(_ memo: MediaMemo) {
        memos.removeAll { $0.id == memo.id }
        memos.append(memo)
        memos.sort { $0.createdAt > $1.createdAt }
        persistIndex()
    }


    private func loadIndexData() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoded = (try? JSONDecoder().decode([MediaMemo].self, from: data)) ?? []

        memos = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder().encode(memos) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
