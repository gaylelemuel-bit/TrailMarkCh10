import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioPlayer: NSObject {
    public private(set) var isPlaying = false

    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    public private(set) var waveform: [Float] = []
    public private(set) var isLoadingWaveform = false

    public private(set) var level: Float = 0

    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    private var player: AVAudioPlayer?
    private var preparedURL: URL?

    public override init() { super.init() }


    public func prepare(url: URL) async {
        guard preparedURL != url else { return }
        preparedURL = url

        waveform = []
        currentTime = 0
        level = 0
        loadPlayer(url: url)

        isLoadingWaveform = true
        let amplitudes = await WaveformLoader.amplitudes(from: url)

        guard preparedURL == url else { return }
        waveform = amplitudes
        isLoadingWaveform = false
    }


    public func play(url: URL) {
        if preparedURL != url {
            preparedURL = url
            waveform = []
            isLoadingWaveform = false
            loadPlayer(url: url)
        } else if player == nil {
            loadPlayer(url: url)
        }

        guard let player else {
            isPlaying = false
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            isPlaying = false
            return
        }

        player.play()
        isPlaying = true
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        level = 0
    }

    public func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        level = 0

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    public func seek(to time: TimeInterval) {
        guard let player else { return }
        let target = min(max(time, 0), player.duration)
        player.currentTime = target
        currentTime = target
    }

    public func tick() {
        guard let player, player.isPlaying else { return }

        currentTime = player.currentTime

        player.updateMeters()
        let channels = max(player.numberOfChannels, 1)
        let decibels = (0..<channels).map { player.averagePower(forChannel: $0) }.max() ?? -160
        let sampled = Self.normalizedLevel(decibels)

        level += (sampled - level) * 0.35
    }


    private func loadPlayer(url: URL) {
        player?.stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.isMeteringEnabled = true
            player.prepareToPlay()

            self.player = player
            self.duration = player.duration
        } catch {
            self.player = nil
            self.duration = 0
            self.isPlaying = false
        }
    }

    private static func normalizedLevel(_ decibels: Float) -> Float {
        let silenceFloor: Float = -55
        guard decibels > silenceFloor else { return 0 }
        return min((decibels - silenceFloor) / -silenceFloor, 1)
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.level = 0
        }
    }
}
