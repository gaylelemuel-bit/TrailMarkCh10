//
//  RecordAudioView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/12/26.
//

import SwiftUI
import TrialMarkCH10Core

struct RecordAudioView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var recorder = AudioRecorder()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text(timeString(recorder.elapsedTime))
                    .font(.system(size: 56, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())

                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 96))
                    .foregroundStyle(recorder.isRecording ? .red : .secondary)
                    .symbolEffect(.pulse, isActive: recorder.isRecording)

                Spacer()

                Button {
                    recorder.isRecording ? finish() : begin()
                } label: {
                    Text(recorder.isRecording ? "Stop & Save" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            recorder.isRecording ? Color.red : .accentColor,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.white)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Record Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if recorder.isRecording {
                            _ = recorder.stop()
                        }
                        dismiss()
                    }
                }
            }
            .task(id: recorder.isRecording) {
                while recorder.isRecording && !Task.isCancelled {
                    recorder.tick()
                    try? await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }

    private func begin() {
        do {
            errorMessage = nil
            try recorder.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finish() {
        guard let result = recorder.stop() else { return }

        do {
            try model.media.add(
                kind: .audio,
                movingFileFrom: result.url,
                duration: result.duration
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
