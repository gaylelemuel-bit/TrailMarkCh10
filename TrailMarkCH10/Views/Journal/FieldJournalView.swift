import SwiftUI
import TrailMarkCH10Core

struct FieldJournalView: View {
    @Environment(AppModel.self) private var model
    @State private var showingAudioRecorder = false
    @State private var showingVideoPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if model.media.memos.isEmpty {
                    TrailMarkEmptyState(
                        title: "Capture the moment",
                        message: "Save a voice note or video while you explore. Every memory stays ready for your journey.",
                        symbol: "waveform.and.mic",
                        actionTitle: "Record Voice Memo"
                    ) {
                        showingAudioRecorder = true
                    }
                } else {
                    List {
                        Section {
                            journalOverview
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        Section("Recent Captures") {
                            ForEach(model.media.memos) { memo in
                                NavigationLink(value: memo) {
                                    MemoRow(memo: memo)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    model.media.delete(model.media.memos[index])
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Field Journal")
            .navigationDestination(for: MediaMemo.self) { memo in
                MemoDetailsView(memo: memo)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Add Video", systemImage: "video.badge.plus") {
                        showingVideoPicker = true
                    }

                    Button("Record Audio", systemImage: "mic.badge.plus") {
                        showingAudioRecorder = true
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
                            duration: duration,
                            coordinate: model.location.currentCoordinate
                        )
                    } catch {
                        model.presentedError = .mediaImport(error.localizedDescription)
                    }
                }
            }
        }
    }

    private var journalOverview: some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform.badge.mic")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(TrailMarkStyle.journalGradient, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(captureCountText)
                    .font(.title3.bold())
                Text("Moments saved from the trail")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .trailMarkCard()
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var captureCountText: String {
        let count = model.media.memos.count
        return "\(count) \(count == 1 ? "capture" : "captures")"
    }
}

struct MemoRow: View {
    let memo: MediaMemo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        memo.kind == .audio
                            ? Color.teal.opacity(0.12)
                            : Color.purple.opacity(0.12)
                    )

                Image(systemName: memo.kind.symbolName)
                    .font(.title3)
                    .foregroundStyle(memo.kind == .audio ? .teal : .purple)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(memo.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(memo.durationText, systemImage: "clock")
                    Text(memo.createdAt, format: .dateTime.month(.abbreviated).day())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
