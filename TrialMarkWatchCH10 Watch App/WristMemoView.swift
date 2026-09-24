//
//  WristMemoView.swift
//  TrialMarkWatchCH10 Watch App
//

import SwiftUI
import TrialMarkCH10Core

/// Lists saved audio memos and plays one back. Recording and storage reuse the
/// shared AudioRecorder / MediaStore from TrialMarkCH10Core.
struct WristMemoView: View {
    @Environment(WatchAppModel.self) private var model
    @State private var isRecordingMemo = false
    @State private var playingMemoID: UUID?

    private var audioMemos: [MediaMemo] {
        model.media.memos.filter { $0.kind == .audio }
    }

    var body: some View {
        Group {
            if audioMemos.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No memos yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(audioMemos) { memo in
                        Button {
                            togglePlayback(for: memo)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isPlaying(memo) ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(memo.durationText)
                                        .monospacedDigit()
                                    Text(memo.createdAt, format: .dateTime.month().day().hour().minute())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteMemos)
                }
            }
        }
        .navigationTitle("Memos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isRecordingMemo = true
                } label: {
                    Image(systemName: "mic.fill")
                }
                .tint(.orange)
            }
        }
        .sheet(isPresented: $isRecordingMemo) {
            RecordMemoSheet()
        }
    }

    private func isPlaying(_ memo: MediaMemo) -> Bool {
        playingMemoID == memo.id && model.player.isPlaying
    }

    private func togglePlayback(for memo: MediaMemo) {
        if isPlaying(memo) {
            model.player.stop()
            playingMemoID = nil
        } else {
            model.player.play(url: model.media.url(for: memo))
            playingMemoID = memo.id
        }
    }

    private func deleteMemos(at offsets: IndexSet) {
        let memos = audioMemos
        for index in offsets {
            let memo = memos[index]
            if playingMemoID == memo.id {
                model.player.stop()
                playingMemoID = nil
            }
            model.media.delete(memo)
        }
    }
}

/// A focused full-screen recording flow: one tap to record, one tap to save.
struct RecordMemoSheet: View {
    @Environment(WatchAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if model.recorder.isRecording {
                Text(elapsedText)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.red)
            } else {
                Text("Tap to record")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                toggleRecording()
            } label: {
                Image(systemName: model.recorder.isRecording ? "stop.fill" : "mic.fill")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.recorder.isRecording ? .red : .orange)
        }
        .padding(.horizontal)
        .task {
            while !Task.isCancelled {
                model.recorder.tick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        .onDisappear {
            // Discard an in-flight recording if the sheet is dismissed mid-way.
            if model.recorder.isRecording {
                _ = model.recorder.stop()
            }
        }
    }

    private var elapsedText: String {
        Duration.seconds(model.recorder.elapsedTime)
            .formatted(.time(pattern: .minuteSecond))
    }

    private func toggleRecording() {
        if model.recorder.isRecording {
            guard let result = model.recorder.stop() else { return }
            do {
                try model.media.add(kind: .audio, movingFileFrom: result.url, duration: result.duration)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            do {
                try model.recorder.start()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    WristMemoView()
        .environment(WatchAppModel())
}
