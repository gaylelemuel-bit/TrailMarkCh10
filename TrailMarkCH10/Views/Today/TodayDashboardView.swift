import SwiftUI
import TrailMarkCH10Core

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                switch model.health.currentAuthStatus {
                case .unknown, .requesting:
                    loadingView

                case .unavailable:
                    HealthAccessStateView(
                        title: "Health Data Unavailable",
                        message: "This device can’t provide Health data.",
                        symbol: "heart.slash.fill"
                    )

                case .denied:
                    HealthAccessStateView(
                        title: "Health Access Needed",
                        message: "Allow TrailMark to read activity data in the Health app.",
                        symbol: "lock.fill",
                        actionTitle: "Try Again"
                    ) {
                        Task {
                            await model.refreshHealthData()
                        }
                    }

                case .authorized:
                    dashboard
                }
            }
            .navigationTitle("Today")
            .toolbar {
                if model.health.currentAuthStatus == .authorized {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task {
                                await model.refreshHealthData()
                            }
                        }
                        .disabled(model.health.isRefreshing)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing your activity summary…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardHeroCard(summary: model.health.todaysSummary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.headline)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                        spacing: 12
                    ) {
                        MetricCard(
                            title: "Distance",
                            value: model.health.todaysSummary.distanceText,
                            symbol: "map.fill",
                            tint: .teal
                        )

                        MetricCard(
                            title: "Active Energy",
                            value: model.health.todaysSummary.activeEnergyText,
                            symbol: "flame.fill",
                            tint: .red
                        )
                    }
                }

                refreshStatus
            }
            .padding()
        }
        .refreshable {
            await model.refreshHealthData()
        }
        .overlay {
            if model.health.isRefreshing {
                ProgressView()
                    .controlSize(.large)
                    .padding()
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Refreshing Health data")
            }
        }
    }

    private var refreshStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: model.connectivity.isActivated ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .foregroundStyle(model.connectivity.isActivated ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.connectivity.isActivated ? "Watch sync ready" : "Watch sync unavailable")
                    .font(.subheadline.weight(.medium))

                if let lastHealthRefresh = model.lastHealthRefresh {
                    Text("Updated \(lastHealthRefresh, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Pull down to refresh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardHeroCard: View {
    let summary: ActivitySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Steps Today", systemImage: "figure.walk")
                .font(.subheadline.weight(.semibold))

            Text(summary.stepsText)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
                .monospacedDigit()

            Text(summary.distanceText)
                .font(.subheadline)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .orange.opacity(0.2), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

private struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .padding(10)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct HealthAccessStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    TodayDashboardView()
        .environment(AppModel())
}
