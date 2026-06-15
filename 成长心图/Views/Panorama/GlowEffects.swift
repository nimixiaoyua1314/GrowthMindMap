import SwiftUI

// MARK: - 外发光修饰器
/// 多层模糊叠加实现柔和光晕效果
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double

    func body(content: Content) -> some View {
        ZStack {
            // 三层模糊叠加制造柔和渐变光晕
            content
                .foregroundColor(color)
                .blur(radius: radius * 1.2)
                .opacity(intensity * 0.3)

            content
                .foregroundColor(color)
                .blur(radius: radius * 0.6)
                .opacity(intensity * 0.5)

            content
                .foregroundColor(color)
                .blur(radius: radius * 0.2)
                .opacity(intensity * 0.7)

            // 原内容在前面
            content
        }
    }
}

extension View {
    /// 添加禅意外发光
    func zenGlow(color: Color = ZenColor.gold, radius: CGFloat = 15, intensity: Double = 0.6) -> some View {
        modifier(GlowModifier(color: color, radius: radius, intensity: intensity))
    }

    /// 核心强光晕
    func coreGlow() -> some View {
        modifier(GlowModifier(color: ZenColor.gold, radius: 25, intensity: 0.8))
    }
}

// MARK: - 呼吸动画修饰器
/// 周期性缩放 + 透明度变化
struct BreathingModifier: ViewModifier {
    @State private var phase: Double = 0
    let duration: Double
    let minScale: CGFloat
    let maxScale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(minScale + (maxScale - minScale) * CGFloat(0.5 + 0.5 * sin(phase)))
            .opacity(0.6 + 0.4 * (0.5 + 0.5 * sin(phase + .pi / 3)))
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
            }
    }
}

extension View {
    /// 添加呼吸效果
    func breathe(duration: Double = ZenAnimation.breathDuration, minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        modifier(BreathingModifier(duration: duration, minScale: minScale, maxScale: maxScale))
    }
}

// MARK: - 涟漪扩散修饰器
struct RippleModifier: ViewModifier {
    @State private var ripples: [(id: UUID, scale: CGFloat, opacity: Double)] = []

    func body(content: Content) -> some View {
        ZStack {
            content

            ForEach(ripples, id: \.id) { ripple in
                Circle()
                    .stroke(ZenColor.gold.opacity(ripple.opacity), lineWidth: 1.5)
                    .scaleEffect(ripple.scale)
                    .opacity(ripple.opacity)
            }
        }
        .onTapGesture { location in
            let id = UUID()
            withAnimation(.easeOut(duration: ZenAnimation.rippleDuration)) {
                ripples.append((id: id, scale: 0.3, opacity: 0.8))
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: ZenAnimation.rippleDuration)) {
                    if let idx = ripples.firstIndex(where: { $0.id == id }) {
                        ripples[idx].scale = 2.5
                        ripples[idx].opacity = 0
                    }
                }
            }

            // 清理
            DispatchQueue.main.asyncAfter(deadline: .now() + ZenAnimation.rippleDuration + 0.1) {
                ripples.removeAll { $0.id == id }
            }
        }
    }
}

extension View {
    /// 点击涟漪效果
    func zenRipple() -> some View {
        modifier(RippleModifier())
    }
}

// MARK: - 微光扫过修饰器
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZenColor.goldLight
                        .opacity(0.15)
                        .frame(width: geometry.size.width * 0.6)
                        .blur(radius: 20)
                        .offset(x: phase * geometry.size.width * 1.5)
                        .mask(content)
                }
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// 微光扫过效果
    func zenShimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - 浮动光点修饰器
struct FloatingGlowModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    let radius: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.15 + 0.08 * CGFloat(sin(Double(offset)))), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .scaleEffect(1 + 0.15 * CGFloat(sin(Double(offset * 1.3))))
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: false)) {
                    offset = 2 * .pi
                }
            }
    }
}

extension View {
    func floatingGlow(radius: CGFloat = 100, color: Color = ZenColor.gold) -> some View {
        modifier(FloatingGlowModifier(radius: radius, color: color))
    }
}
