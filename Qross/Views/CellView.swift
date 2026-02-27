import SwiftUI

struct CellView: View {
    let cell: Cell
    let topicColor: Color
    let variant: GameVariant
    let isStart: Bool
    let isEnd: Bool
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

                // Start/end markers
                if isStart && cell.state != .correct {
                    Text("S")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
                if isEnd && cell.state != .correct {
                    Text("E")
                        .font(.caption2.bold())
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
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .pulseAnimation()
                default:
                    EmptyView()
                }
            }
        }
        .disabled(cell.state != .available)
        .aspectRatio(1, contentMode: .fit)
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
