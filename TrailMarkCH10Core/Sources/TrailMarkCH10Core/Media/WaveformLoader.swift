import Foundation
import AVFoundation
import Accelerate

public enum WaveformLoader {
    public static let defaultBarCount = 96

    public static func amplitudes(from url: URL, barCount: Int = defaultBarCount) async -> [Float] {
        #if os(watchOS)
        return []
        #else
        return await Task.detached(priority: .userInitiated) {
            (try? await decode(url: url, barCount: barCount)) ?? []
        }.value
        #endif
    }
}

#if !os(watchOS)

extension WaveformLoader {
    private static var window: Int { 256 }


    private static func decode(url: URL, barCount: Int) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return [] }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        reader.startReading()

        var readings: [Float] = []
        var pending: [Float] = []

        while reader.status == .reading, let sampleBuffer = output.copyNextSampleBuffer() {
            defer { CMSampleBufferInvalidate(sampleBuffer) }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            let byteCount = CMBlockBufferGetDataLength(blockBuffer)
            guard byteCount >= 2 else { continue }

            var pcm = [Int16](repeating: 0, count: byteCount / 2)
            let copied = pcm.withUnsafeMutableBytes { buffer in
                CMBlockBufferCopyDataBytes(blockBuffer,
                                           atOffset: 0,
                                           dataLength: byteCount,
                                           destination: buffer.baseAddress!)
            }
            guard copied == noErr else { continue }

            var frames = [Float](repeating: 0, count: pcm.count)
            vDSP.convertElements(of: pcm, to: &frames)
            pending.append(contentsOf: frames)

            var offset = 0
            while offset + window <= pending.count {
                readings.append(vDSP.rootMeanSquare(pending[offset..<(offset + window)]))
                offset += window
            }
            pending.removeFirst(offset)
        }

        guard reader.status != .failed else { return [] }

        if !pending.isEmpty {
            readings.append(vDSP.rootMeanSquare(pending))
        }

        return normalize(bucket(readings, into: barCount))
    }


    private static func bucket(_ readings: [Float], into barCount: Int) -> [Float] {
        guard barCount > 0 else { return [] }
        guard !readings.isEmpty else { return Array(repeating: 0, count: barCount) }

        return (0..<barCount).map { index in
            let start = index * readings.count / barCount
            let end = min(max(start + 1, (index + 1) * readings.count / barCount), readings.count)
            return readings[start..<end].max() ?? 0
        }
    }

    private static func normalize(_ values: [Float]) -> [Float] {
        guard let peak = values.max(), peak > 0 else { return values }
        return values.map { min(pow($0 / peak, 0.7), 1) }
    }
}

#endif
