import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    private let count = 80

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startTime)
            Canvas { ctx, size in
                for p in particles {
                    let t = elapsed - p.delay
                    guard t > 0 else { continue }

                    let progress = t / p.lifetime
                    guard progress < 1.0 else { continue }

                    let x = size.width * p.startX + p.velocityX * t
                    let y = size.height * p.startY + p.velocityY * t + 400 * t * t // gravity
                    let opacity = 1.0 - progress
                    let rotation = Angle.degrees(p.spin * t * 360)
                    let s = p.size * (1.0 - progress * 0.3)

                    ctx.opacity = opacity
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: rotation)

                    if p.isCircle {
                        let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                        ctx.fill(Circle().path(in: rect), with: .color(p.color))
                    } else {
                        let rect = CGRect(x: -s / 2, y: -s / 4, width: s, height: s / 2)
                        ctx.fill(RoundedRectangle(cornerRadius: 2).path(in: rect), with: .color(p.color))
                    }

                    ctx.rotate(by: -rotation)
                    ctx.translateBy(x: -x, y: -y)
                    ctx.opacity = 1.0
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            startTime = .now
            particles = (0..<count).map { _ in ConfettiParticle() }
        }
    }
}

private struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let velocityX: Double
    let velocityY: Double
    let size: Double
    let color: Color
    let isCircle: Bool
    let spin: Double
    let lifetime: Double
    let delay: Double

    private static let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .mint]

    init() {
        startX = Double.random(in: 0.3...0.7)
        startY = 0.4
        velocityX = Double.random(in: -120...120)
        velocityY = Double.random(in: -500 ... -200)
        size = Double.random(in: 6...12)
        color = Self.colors.randomElement()!
        isCircle = Bool.random()
        spin = Double.random(in: 0.5...2.0) * (Bool.random() ? 1 : -1)
        lifetime = Double.random(in: 2.0...3.0)
        delay = Double.random(in: 0...0.15)
    }
}
