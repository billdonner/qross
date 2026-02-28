import SwiftUI

struct CellView: View {
    let cell: Cell
    let topicColor: Color
    let variant: GameVariant
    let isEnd: Bool
    let isCornerPick: Bool // true when choosing corner and this is an available corner
    let onTap: () -> Void

    private var showColor: Bool {
        variant != .blind || cell.state == .correct || cell.state == .wrong
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: cell.state == .available ? 4 : 2)

                // Corner-pick pulsing indicator
                if isCornerPick && cell.state == .available {
                    CornerPulseIndicator()
                }

                // Goal marker — small star on the destination corner
                if isEnd && cell.state != .correct {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                }

                // State overlays
                switch cell.state {
                case .correct:
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                case .wrong:
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                case .available:
                    if !isCornerPick {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .pulseAnimation()
                    }
                default:
                    EmptyView()
                }
            }
        }
        .disabled(cell.state != .available)
        .aspectRatio(1, contentMode: .fill)
    }

    private var backgroundColor: Color {
        switch cell.state {
        case .correct:
            return showColor ? topicColor : .green
        case .wrong:
            return Color.red.opacity(0.6)
        case .available:
            return showColor ? topicColor.opacity(0.7) : Color.gray.opacity(0.4)
        case .untouched:
            return showColor ? topicColor.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }

    private var shadowColor: Color {
        cell.state == .available ? topicColor.opacity(0.5) : .clear
    }
}

// MARK: - Corner pulse indicator (three concentric rings)

struct CornerPulseIndicator: View {
    @State private var animating = false

    var body: some View {
        ZStack {
            // Outer ring — fades out as it expands
            Circle()
                .stroke(.white.opacity(animating ? 0.0 : 0.4), lineWidth: 2)
                .frame(width: animating ? 28 : 14, height: animating ? 28 : 14)

            // Inner ring — slightly delayed feel via different opacity range
            Circle()
                .stroke(.white.opacity(animating ? 0.15 : 0.6), lineWidth: 1.5)
                .frame(width: animating ? 20 : 12, height: animating ? 20 : 12)

            // Core dot
            Circle()
                .fill(.white.opacity(animating ? 0.5 : 0.9))
                .frame(width: 10, height: 10)
        }
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: animating
        )
        .onAppear { animating = true }
    }
}

// MARK: - Pulse animation for available cells

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseModifier())
    }
}
