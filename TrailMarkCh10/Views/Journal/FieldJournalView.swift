//
//  FieldJournalView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/12/26.
//

import SwiftUI
import AVFoundation
import TrialMarkCH10Core

struct FieldJournalView: View {
    @Environment(AppModel.self) private var model

    @State private var showingAudioRecorder = false
    @State private var showingVideoPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if model.media.memos.isEmpty {
                    ContentUnavailableView(
                        "No memos yet",
                        systemImage: "waveform",
                        description: Text("Record a voice or video memo to start your journey")
                    )
                } else {
                    List {
                        ForEach(model.media.memos) { memo in
                            NavigationLink(value: memo) {
                                MemoRow(memo: memo)
                            }
                        }
                        .onDelete { offsets in
                            model.media.delete(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Field Journal")
            .navigationDestination(for: MediaMemo.self) { memo in
                MemoDetailsView(memo: memo)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingAudioRecorder = true
                    } label: {
                        Image(systemName: "mic.badge.plus")
                    }

                    Button {
                        showingVideoPicker = true
                    } label: {
                        Image(systemName: "video.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAudioRecorder) {
                RecordAudioView()
            }
            .sheet(isPresented: $showingVideoPicker) {
                VideoCaptureView { url, duration in
                    do {
                        try model.media.add(
                            kind: .video,
                            movingFileFrom: url,
                            duration: duration
                        )
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .alert("Unable to Save Memo", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

private struct MemoRow: View {
    @Environment(AppModel.self) private var model
    @State private var thumbnail: UIImage?

    let memo: MediaMemo

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: memo.kind.symbolName)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 54)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(memo.durationText, systemImage: "clock")
                    Label(memo.kind.displayName, systemImage: memo.kind.symbolName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task(id: memo.id) {
            guard memo.kind == .video else { return }
            thumbnail = await makeVideoThumbnail(url: model.media.url(for: memo))
        }
    }

    private func makeVideoThumbnail(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        guard let result = try? await generator.image(at: .zero) else {
            return nil
        }

        return UIImage(cgImage: result.image)
    }
}
