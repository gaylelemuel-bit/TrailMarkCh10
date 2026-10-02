import SwiftUI

enum TrailMarkStyle {
    static let cornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 16

    static let primaryGradient = LinearGradient(
        colors: [Color.orange, Color.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let recoveryGradient = LinearGradient(
        colors: [Color.indigo, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let journalGradient = LinearGradient(
        colors: [Color.teal, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct TrailMarkCardModifier: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                .background.secondary,
                in: RoundedRectangle(
                    cornerRadius: TrailMarkStyle.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: TrailMarkStyle.cornerRadius,
                    style: .continuous
                )
                .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

extension View {
    func trailMarkCard(padding: CGFloat = 18) -> some View {
        modifier(TrailMarkCardModifier(padding: padding))
    }
}

struct TrailMarkEmptyState: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.14))
                    .frame(width: 96, height: 96)

                Image(systemName: symbol)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(TrailMarkStyle.primaryGradient)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(32)
        .frame(maxWidth: 460)
        .accessibilityElement(children: .contain)
    }
}
