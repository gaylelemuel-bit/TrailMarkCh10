import SwiftUI
import TrailMarkCH10Core

struct JourneyListView: View {
    @Environment(AppModel.self) private var model
    @State private var showingRecorder = false

    var body: some View {
        NavigationStack {
            Group {
                if model.journeyStore.journeys.isEmpty {
                    TrailMarkEmptyState(
                        title: "Your trail starts here",
                        message: "Record a journey to preserve its route, activity, and field notes in one place.",
                        symbol: "map.fill",
                        actionTitle: "Record Journey"
                    ) {
                        showingRecorder = true
                    }
                } else {
                    List {
                        Section {
                            journeyOverview
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        Section("Recent Adventures") {
                            ForEach(model.journeyStore.journeys) { journey in
                                NavigationLink(value: journey) {
                                    JourneyRow(journey: journey)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete {
                                model.journeyStore.delete(at: $0)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journeys")
            .navigationDestination(for: Journey.self) { journey in
                JourneyDetailsView(journey: journey)
            }
            .navigationDestination(for: MediaMemo.self) { memo in
                MemoDetailsView(memo: memo)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Record Journey", systemImage: "plus") {
                        showingRecorder = true
                    }
                }
            }
            .sheet(isPresented: $showingRecorder) {
                RecordJourneyView()
            }
        }
    }

    private var journeyOverview: some View {
        HStack(spacing: 16) {
            Image(systemName: "mountain.2.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(TrailMarkStyle.primaryGradient, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\\(model.journeyStore.journeys.count) adventures")
                    .font(.title3.bold())

                Text(totalDistance)
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

    private var totalDistance: String {
        let meters = model.journeyStore.journeys.reduce(0) {
            $0 + $1.distanceMeters
        }
        return Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
}

struct JourneyRow: View {
    let journey: Journey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: journey.workout == nil ? "map.fill" : "figure.walk")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 46, height: 46)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(journey.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(distanceText, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    Label("\\(journey.memoIDs.count)", systemImage: "waveform")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(journey.dateText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }

    private var distanceText: String {
        Measurement(value: journey.distanceMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
}
