//
//  MemoDetailsView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/12/26.
//

import SwiftUI
import AVKit
import TrialMarkCH10Core

struct MemoDetailsView: View {
    @Environment(AppModel.self) private var model
    @State private var audioPlayer = AudioPlayer()

    let memo: MediaMemo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch memo.kind {
                case .video:
                    VideoPlayer(player: AVPlayer(url: model.media.url(for: memo)))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .audio:
                    audioControls
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(memo.kind.displayName, systemImage: memo.kind.symbolName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(memo.title)
                        .font(.title2.bold())
                    Text(memo.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(memo.durationTest)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(memo.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private var audioControls: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 80))
                .foregroundStyle(.teal)
                .symbolEffect(.variableColor, isActive: audioPlayer.isPlaying)

            Button {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                } else {
                    audioPlayer.play(url: model.media.url(for: memo))
                }
            } label: {
                Label(
                    audioPlayer.isPlaying ? "Stop" : "Play",
                    systemImage: audioPlayer.isPlaying ? "stop.circle.fill" : "play.circle.fill"
                )
                .font(.title2)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
