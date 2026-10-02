import SwiftUI
import TrailMarkCH10Core
import WidgetKit

struct TrailMarkMetricEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedMetricSnapshot
}

struct TrailMarkMetricProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrailMarkMetricEntry {
        TrailMarkMetricEntry(
            date: .now,
            snapshot: SharedMetricSnapshot(
                steps: 4_820,
                distanceMeters: 3_420,
                activeEnergyKcal: 286,
                updatedAt: .now
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (TrailMarkMetricEntry) -> Void
    ) {
        completion(TrailMarkMetricEntry(date: .now, snapshot: SharedMetricStore.load()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<TrailMarkMetricEntry>) -> Void
    ) {
        let entry = TrailMarkMetricEntry(date: .now, snapshot: SharedMetricStore.load())
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct TrailMarkMetricWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TrailMarkMetricEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.snapshot.steps, in: 0...10_000) {
                Image(systemName: "figure.walk")
            } currentValueLabel: {
                Text(entry.snapshot.steps, format: .number.notation(.compactName))
                    .font(.caption2)
            }
            .gaugeStyle(.accessoryCircular)

        case .accessoryInline:
            Label(
                "\(entry.snapshot.steps.formatted(.number.precision(.fractionLength(0)))) steps",
                systemImage: "figure.walk"
            )

        default:
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading) {
                    Text("Steps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.snapshot.steps, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                        .monospacedDigit()
                }
            }
        }
    }
}

struct TrailMarkMetricWidget: Widget {
    let kind = SharedMetricStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrailMarkMetricProvider()) { entry in
            TrailMarkMetricWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("TrailMark Steps")
        .description("See today’s steps from TrailMark.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct TrailMarkMetricWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrailMarkMetricWidget()
    }
}
