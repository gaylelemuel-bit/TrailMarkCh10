import SwiftUI
import Charts
import TrailMarkCH10Core

struct RecoveryView: View {
    @Environment(AppModel.self) private var model

    @State private var saveState: SaveState = .idle

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sleepCard
                    energyChartCard
                }
                .padding()
            }
            .navigationTitle("Recovery")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }


    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last night's sleep", systemImage: "bed.double.fill")
                .font(.headline)

            Text(model.health.sleep.asleepSeconds > 0 ? model.health.sleep.durationText : "No sleep data")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.indigo)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }


    private var energyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active energy · last 7 days", systemImage: "flame.fill")
                .font(.headline)

            if model.health.energyTrend.isEmpty {
                Text("No energy data yet.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(model.health.energyTrend) { point in
                    BarMark(
                        x: .value("Day", point.day, unit: .day),
                        y: .value("kcal", point.activeEnergyKcal)
                    )
                    .foregroundStyle(.red.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }


    private var saveWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Log a sample workout", systemImage: "figure.walk")
                .font(.headline)

            Text("Saves a 30-minute walk to HealthKit so you can confirm it appears in the Health app.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(action: saveSampleWorkout) {
                HStack {
                    if saveState == .saving {
                        ProgressView().padding(.trailing, 4)
                    }
                    Text(buttonTitle)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(saveState == .saving)

            if case .failed(let message) = saveState {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var buttonTitle: String {
        switch saveState {
        case .saved: return "Saved ✓ — check the Health app"
        default: return "Save sample workout"
        }
    }


    private func refresh() async {
        await model.health.refreshLastNightSleep()
        await model.health.refreshEnergyTrend()
    }

    private func saveSampleWorkout() {
        saveState = .saving

        let end = Date()
        let record = WorkoutRecord(
            start: end.addingTimeInterval(-1800),
            end: end,
            activeEnergyKcal: 180,
            distanceMeters: 2400
        )

        Task {
            do {
                try await model.health.save(record)
                saveState = .saved
                await model.health.refreshEnergyTrend()
            } catch {
                saveState = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview {
    RecoveryView()
        .environment(AppModel())
}
