import SwiftUI

// MARK: - 粒子模型
struct ZenParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var phase: Double      // 0...2π，用于摆动
    var lifeProgress: Double // 0...1 生命周期
    var driftAngle: Double  // 偏移角度
}

// MARK: - 粒子系统管理器
@MainActor
final class ParticleManager: ObservableObject {
    @Published var particles: [ZenParticle] = []
    private let particleCount: Int
    private var timer: Timer?

    init(count: Int = 60) {
        self.particleCount = count
        spawnInitialParticles()
    }

    private func spawnInitialParticles() {
        particles = (0..<particleCount).map { _ in createParticle(initialSpawn: true) }
    }

    private func createParticle(initialSpawn: Bool) -> ZenParticle {
        let size = CGFloat.random(in: 2...6)
        let margin: CGFloat = 40
        let x = CGFloat.random(in: margin...UIScreen.main.bounds.width - margin)
        let y = initialSpawn
            ? CGFloat.random(in: 80...UIScreen.main.bounds.height - 160)
            : UIScreen.main.bounds.height - margin + 20

        return ZenParticle(
            x: x,
            y: y,
            size: size,
            opacity: initialSpawn ? CGFloat.random(in: 0.1...0.5) : 0,
            speed: CGFloat.random(in: 0.15...0.4),
            phase: CGFloat.random(in: 0...(2 * .pi)),
            lifeProgress: initialSpawn ? CGFloat.random(in: 0...1) : 0,
            driftAngle: CGFloat.random(in: -0.02...0.02)
        )
    }

    func update(elapsed: TimeInterval) {
        let dt = min(elapsed, 0.1)
        let screenHeight = UIScreen.main.bounds.height
        let topMargin: CGFloat = 60
        let bottomMargin: CGFloat = 100
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = screenHeight / 2
        let exclusionRadius: CGFloat = 120 // 核心区域不穿越

        for i in particles.indices {
            var p = particles[i]

            // 生命周期推进
            p.lifeProgress += dt * p.speed * 0.15
            if p.lifeProgress > 1 {
                // 重生
                p = createParticle(initialSpawn: false)
                p.lifeProgress = 0
                particles[i] = p
                continue
            }

            // 透明度曲线：淡入 → 保持 → 淡出
            let fadeIn = min(p.lifeProgress * 4, 1.0)
            let fadeOut = max(0, (1 - p.lifeProgress) * 3)
            p.opacity = min(fadeIn, fadeOut) * CGFloat.random(in: 0.3...0.7)

            // 垂直漂浮
            p.y -= dt * p.speed * 15

            // 水平正弦摆动
            p.x += CGFloat(sin(p.phase + p.lifeProgress * 6)) * dt * 8 * p.speed
            p.x += p.driftAngle * dt * 5

            // 轻微避开中心区域
            let dx = p.x - centerX
            let dy = p.y - centerY
            let dist = sqrt(dx * dx + dy * dy)
            if dist < exclusionRadius && dist > 0 {
                let pushStrength = (exclusionRadius - dist) / exclusionRadius
                p.x += (dx / dist) * pushStrength * dt * 30
                p.y += (dy / dist) * pushStrength * dt * 30
            }

            // 边界检测：超出屏幕 → 重生
            if p.y < topMargin || p.y > screenHeight - bottomMargin ||
               p.x < -30 || p.x > UIScreen.main.bounds.width + 30 {
                p = createParticle(initialSpawn: false)
                p.lifeProgress = 0
            }

            particles[i] = p
        }
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update(elapsed: 1/30)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - 粒子 Canvas 视图
struct ZenParticleField: View {
    @StateObject private var manager = ParticleManager(count: 65)
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            for particle in manager.particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )

                // 粒子光晕
                let glowRect = rect.insetBy(dx: -particle.size, dy: -particle.size)
                let glowPath = Path(ellipseIn: glowRect)
                context.fill(
                    glowPath,
                    with: .color(ZenColor.gold.opacity(particle.opacity * 0.15))
                )
                context.addFilter(.blur(radius: particle.size * 1.5))

                // 粒子核心
                let path = Path(ellipseIn: rect)
                context.fill(
                    path,
                    with: .color(ZenColor.goldLight.opacity(particle.opacity))
                )

                // 小粒子加亮
                if particle.size < 3.5 {
                    context.fill(
                        path,
                        with: .color(ZenColor.goldPale.opacity(particle.opacity * 0.6))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { manager.start() }
        .onDisappear { manager.stop() }
    }
}

// MARK: - TimelineView 备用方案 (性能更好但 iOS 15+)
struct ZenParticleFieldTimeline: View {
    let particleCount: Int

    init(count: Int = 60) {
        self.particleCount = count
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let date = timeline.date.timeIntervalSince1970
            Canvas { context, size in
                drawParticles(context: &context, size: size, time: date)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticles(context: inout GraphicsContext, size: CGSize, time: Double) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let exclusionRadius: CGFloat = min(size.width, size.height) * 0.18

        for i in 0..<particleCount {
            let seed = Double(i) * 137.508 // 黄金角度分布
            let baseX = centerX + CGFloat(sin(seed + time * 0.3)) * size.width * 0.45
            let baseY = centerY + CGFloat(cos(seed * 1.7 + time * 0.15)) * size.height * 0.42

            // 避开中心
            var px = baseX
            var py = baseY
            let dx = px - centerX
            let dy = py - centerY
            let dist = sqrt(dx * dx + dy * dy)
            if dist < exclusionRadius {
                px = centerX + (dx / dist) * exclusionRadius
                py = centerY + (dy / dist) * exclusionRadius
            }

            let floatX = CGFloat(sin(time * 0.7 + seed)) * 12
            let floatY = CGFloat(cos(time * 0.5 + seed * 0.7)) * 8
            px += floatX
            py += floatY

            let lifePhase = (time * 0.08 + seed * 0.3).truncatingRemainder(dividingBy: 2 * .pi)
            let opacity: Double
            if lifePhase < .pi {
                opacity = min(lifePhase / (.pi * 0.3), 1.0) * 0.5
            } else {
                opacity = max(0, (2 * .pi - lifePhase) / (.pi * 0.5)) * 0.5
            }

            let particleSize = 2.0 + (sin(seed * 3.7) + 1) * 2.0

            // 光晕
            let glowRect = CGRect(x: px - particleSize * 2, y: py - particleSize * 2,
                                   width: particleSize * 4, height: particleSize * 4)
            context.fill(Path(ellipseIn: glowRect),
                        with: .color(ZenColor.gold.opacity(opacity * 0.12)))
            context.addFilter(.blur(radius: 4))

            // 核心
            let rect = CGRect(x: px - particleSize/2, y: py - particleSize/2,
                             width: particleSize, height: particleSize)
            context.fill(Path(ellipseIn: rect),
                        with: .color(ZenColor.goldLight.opacity(opacity)))
        }
    }
}
