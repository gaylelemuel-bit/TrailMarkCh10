import SwiftUI
import TrailMarkCH10Core

struct WristMemoView: View {
    @Environment(WatchModel.self) private var model

    @State private var recorder = AudioRecorder()
    @State private var player = AudioPlayer()
    @State private var errorMessage = ""
    @State private var isShowingError = false

    var body: some View {
        List {
            Section {
                Button {
                    recorder.isRecording ? finish() : start()
                } label: {
                    Label(
                        recorder.isRecording ? "Stop \(elapsed)" : "Record Memo",
                        systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(recorder.isRecording ? .red : .accentColor)
                }
                .buttonStyle(.borderedProminent)
                .tint(recorder.isRecording ? .red.opacity(0.2) : .accentColor.opacity(0.2))
            } footer: {
                syncFooter
            }

            Section("Memos") {
                if model.media.memos.isEmpty {
                    Label("No recordings yet", systemImage: "waveform")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.media.memos) { memo in
                        Button {
                            player.play(url: model.media.url(for: memo))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(memo.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text(memo.durationText)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                                syncIcon(for: memo)
                            }
                        }
                        .swipeActions {
                            if model.connectivity.failedMemoIDs.contains(memo.id) {
                                Button("Resend", systemImage: "arrow.clockwise") {
                                    model.resend(memo)
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Voice Memos")
        .task(id: recorder.isRecording) {
            while recorder.isRecording && !Task.isCancelled {
                recorder.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onDisappear {
            player.stop()
        }
        .alert("Voice Memo", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func start() {
        do {
            try recorder.start()
        } catch {
            present(error)
        }
    }

    private func finish() {
        guard let result = recorder.stop() else {
            errorMessage = "The recording could not be completed."
            isShowingError = true
            return
        }

        do {
            try model.saveAndSync(memoFrom: result.url, duration: result.duration)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }

    @ViewBuilder
    private var syncFooter: some View {
        let connectivity = model.connectivity
        let waiting = connectivity.pendingMemoIDs.count + connectivity.pendingRecordCount

        VStack(alignment: .leading, spacing: 2) {
            if waiting > 0 {
                Text("\(waiting) \(waiting == 1 ? "item" : "items") waiting for iPhone")
            }

            if let error = connectivity.lastError {
                Text(error)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func syncIcon(for memo: MediaMemo) -> some View {
        let connectivity = model.connectivity

        if connectivity.pendingMemoIDs.contains(memo.id) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Waiting to sync")
        } else if connectivity.failedMemoIDs.contains(memo.id) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityLabel("Sync failed")
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Synced")
        }
    }

    private var elapsed: String {
        Duration.seconds(recorder.elapsedTime)
            .formatted(.time(pattern: .minuteSecond))
    }
}
