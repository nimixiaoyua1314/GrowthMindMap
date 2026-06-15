import SwiftUI

/// 特质雷达图 — 修复标签漂移
struct TraitRadarChartView: View {
    let traitScores: [String: Double]

    @State private var animationProgress: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    private var sortedTraits: [(String, Double)] {
        traitScores.sorted { $0.key < $1.key }
    }
    private var traitNames: [String] { sortedTraits.map { $0.0 } }
    private var normalizedValues: [Double] { sortedTraits.map { $0.1 / 100.0 } }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height) * 0.82
                let chartCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let ringRadius = size / 2
                let labelRadius = ringRadius * 1.18 // 标签在环外18%，确保 fit
                let angleStep = traitNames.isEmpty ? 0 : 2 * .pi / CGFloat(traitNames.count)

                ZStack {
                    // 网格
                    radarGrid(center: chartCenter, radius: ringRadius, angleStep: angleStep)

                    // 数据
                    radarData(center: chartCenter, radius: ringRadius, angleStep: angleStep)
                        .opacity(animationProgress)

                    // 标签 — 用 overlay + offset 而非 position
                    ForEach(0..<traitNames.count, id: \.self) { i in
                        let angle = angleStep * CGFloat(i) - .pi / 2
                        let lx = chartCenter.x + labelRadius * CGFloat(cos(angle))
                        let ly = chartCenter.y + labelRadius * CGFloat(sin(angle))

                        Text(traitNames[i])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? ZenColor.darkTextSecondary : ZenColor.inkMedium)
                            .fixedSize()
                            .position(x: lx, y: ly)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // 图例
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle().fill(Color.themePrimary).frame(width: 6, height: 6)
                    Text("得分").font(.caption2).foregroundColor(.themeTextTertiary)
                }
                HStack(spacing: 4) {
                    Circle().stroke(Color.themePrimary, lineWidth: 1).frame(width: 6, height: 6)
                    Text("满分").font(.caption2).foregroundColor(.themeTextTertiary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) { animationProgress = 1 }
        }
    }

    // MARK: - 网格
    private func radarGrid(center: CGPoint, radius: CGFloat, angleStep: Double) -> some View {
        let levels = 5
        let gridC = colorScheme == .dark ? ZenColor.darkTextSecondary.opacity(0.15) : Color.themeTextTertiary.opacity(0.2)

        return ZStack {
            ForEach(1...levels, id: \.self) { level in
                let r = radius * CGFloat(level) / CGFloat(levels)
                Path { p in
                    for i in 0..<traitNames.count {
                        let a = angleStep * CGFloat(i) - .pi / 2
                        let pt = CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                    p.closeSubpath()
                }
                .stroke(gridC, lineWidth: 0.5)
            }
            ForEach(0..<traitNames.count, id: \.self) { i in
                let a = angleStep * CGFloat(i) - .pi / 2
                Path { p in
                    p.move(to: center)
                    p.addLine(to: CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a)))
                }
                .stroke(gridC, lineWidth: 0.5)
            }
        }
    }

    private func dataPath(center: CGPoint, radius: CGFloat, angleStep: Double) -> Path {
        Path { p in
            for i in 0..<traitNames.count {
                let a = angleStep * CGFloat(i) - .pi / 2
                let val = i < normalizedValues.count ? normalizedValues[i] * animationProgress : 0
                let r = radius * CGFloat(val)
                let pt = CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
        }
    }

    // MARK: - 数据
    private func radarData(center: CGPoint, radius: CGFloat, angleStep: Double) -> some View {
        let fillC = Color.themePrimary.opacity(0.12)
        let strokeC = Color.themePrimary
        let path = dataPath(center: center, radius: radius, angleStep: angleStep)

        return ZStack {
            path.fill(fillC)
            path.stroke(strokeC, lineWidth: 1.5)

            ForEach(0..<traitNames.count, id: \.self) { i in
                let a = angleStep * CGFloat(i) - .pi / 2
                let val = i < normalizedValues.count ? normalizedValues[i] * animationProgress : 0
                let r = radius * CGFloat(val)
                Circle()
                    .fill(strokeC)
                    .frame(width: 6, height: 6)
                    .position(x: center.x + r * cos(a), y: center.y + r * sin(a))
            }
        }
    }
}
