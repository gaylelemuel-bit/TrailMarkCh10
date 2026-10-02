import Charts
import SwiftUI
import TrailMarkCH10Core

struct RecoveryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sleepHero
                    insights
                    energyChartCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recovery")
            .task {
                await refresh()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    private var sleepHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Last Night", systemImage: "moon.stars.fill")
                    .font(.headline)

                Spacer()

                Image(systemName: "bed.double.fill")
                    .font(.title2)
            }

            Text(
                model.health.sleep.asleepSeconds > 0
                    ? model.health.sleep.durationText
                    : "No sleep data"
            )
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .contentTransition(.numericText())

            Text(recoveryMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            TrailMarkStyle.recoveryGradient,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .shadow(color: .indigo.opacity(0.22), radius: 18, y: 9)
        .accessibilityElement(children: .combine)
    }

    private var insights: some View {
        HStack(spacing: 12) {
            RecoveryInsight(
                title: "Sleep",
                value: sleepScore,
                symbol: "sparkles",
                tint: .indigo
            )

            RecoveryInsight(
                title: "Daily Burn",
                value: averageEnergy,
                symbol: "flame.fill",
                tint: .orange
            )
        }
    }

    private var energyChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Energy Trend")
                        .font(.headline)
                    Text("Last seven days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.orange)
            }

            if model.health.energyTrend.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Wear your Apple Watch to build your trend.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 190)
            } else {
                Chart(model.health.energyTrend) { point in
                    BarMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("Active Energy", point.activeEnergyKcal)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
                .accessibilityChartDescriptor(self)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trailMarkCard()
    }

    private var recoveryMessage: String {
        let hours = model.health.sleep.hours

        if hours >= 8 {
            return "You’re well rested and ready for a bigger adventure."
        } else if hours >= 6 {
            return "A moderate day can help you stay consistent."
        } else if hours > 0 {
            return "Consider a lighter route and an earlier recovery."
        } else {
            return "Sleep insights appear after Health records a night."
        }
    }

    private var sleepScore: String {
        guard model.health.sleep.hours > 0 else { return "—" }
        return model.health.sleep.hours >= 7 ? "Ready" : "Recover"
    }

    private var averageEnergy: String {
        guard !model.health.energyTrend.isEmpty else { return "—" }
        let total = model.health.energyTrend.reduce(0) {
            $0 + $1.activeEnergyKcal
        }
        return Int(total / Double(model.health.energyTrend.count)).formatted() + " kcal"
    }

    private func refresh() async {
        await model.health.refreshLastNightSleep()
        await model.health.refreshEnergyTrend()
    }
}

private struct RecoveryInsight: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: Circle())

            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trailMarkCard()
        .accessibilityElement(children: .combine)
    }
}

extension RecoveryView: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Day",
            categoryOrder: model.health.energyTrend.map {
                $0.day.formatted(.dateTime.weekday(.abbreviated))
            }
        )

        let maxEnergy = model.health.energyTrend.map(\.activeEnergyKcal).max() ?? 1
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Active Energy",
            range: 0...max(maxEnergy, 1),
            gridlinePositions: []
        ) { value in
            value.formatted(.number.precision(.fractionLength(0))) + " kilocalories"
        }

        let series = AXDataSeriesDescriptor(
            name: "Active Energy",
            isContinuous: false,
            dataPoints: model.health.energyTrend.map {
                AXDataPoint(
                    x: $0.day.formatted(.dateTime.weekday(.abbreviated)),
                    y: $0.activeEnergyKcal
                )
            }
        )

        return AXChartDescriptor(
            title: "Seven-day active energy",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

#Preview {
    RecoveryView()
        .environment(AppModel())
}
