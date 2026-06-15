import SwiftUI

/// 全景同心圆 — 支持双指缩放 + 单指移动
struct PanoramaView: View {
    @ObservedObject var viewModel: PanoramaViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var ambient = AmbientSoundEngine()
    var onNavigate: ((Int) -> Void)?

    // 手势状态
    @State private var scale: CGFloat = 2.0       // 默认 2x 放大
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 2.0
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let sz = min(geo.size.width, geo.size.height)
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let maxR = (sz / 2) * 0.88

            ZStack {
                bgColor.ignoresSafeArea()

                // ── 整个同心圆组，应用缩放+偏移 ──
                Group {
                    // 彩色参考圆环
                    let ringColors: [Color] = [ZenColor.gold, ZenColor.vermilionLight, ZenColor.jade, Color.themeInfo]
                    let ringOpacities: [Double] = [0.15, 0.12, 0.10, 0.08]
                    ForEach(0..<4, id: \.self) { i in
                        let r = ringR(i, maxR: maxR)
                        Circle()
                            .stroke(ringColors[i].opacity(ringOpacities[i]), lineWidth: 1.2)
                            .frame(width: r * 2, height: r * 2)
                        Circle()
                            .fill(ringColors[i].opacity(0.03))
                            .frame(width: r * 2, height: r * 2)
                    }

                    // 环标题
                    let titles = ["经历", "情绪", "个性", "领域"]
                    ForEach(0..<min(viewModel.rings.count, 4), id: \.self) { i in
                        let r = ringR(i, maxR: maxR)
                        Text(titles[i])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ZenColor.inkLight.opacity(0.55))
                            .offset(y: -r - 10)
                    }

                    // 环上内容
                    RingItemsLayer(rings: viewModel.rings, centerX: 0, centerY: 0, maxR: maxR)

                    // 中心
                    CoreView(text: viewModel.centerText, sub: viewModel.centerSub,
                             radius: ringR(0, maxR: maxR) * 0.75)
                }
                .scaleEffect(scale)
                .offset(offset)
                .position(x: cx, y: cy)

                // 空引导
                if !viewModel.hasData {
                    Text("点击底部「记录」开始")
                        .font(.caption).foregroundColor(.themeTextTertiary)
                        .position(x: cx, y: geo.size.height - 50)
                }

                // 音乐按钮
                VStack { HStack { Spacer()
                    Button { ambient.isPlaying ? ambient.stop() : ambient.start() } label: {
                        Image(systemName: ambient.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 13))
                            .foregroundColor(ambient.isPlaying ? ZenColor.gold : ZenColor.inkPale)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.ultraThinMaterial))
                    }.padding(.trailing, 16).padding(.top, 8)
                }; Spacer() }

                // 缩放提示
                if scale == 2.0 && offset == .zero {
                    Text("双指缩放 · 单指移动")
                        .font(.system(size: 9)).foregroundColor(.themeTextTertiary.opacity(0.5))
                        .position(x: cx, y: geo.size.height - 40)
                }
            }
            // 手势
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { v in scale = min(max(lastScale * v, 0.5), 6.0) }
                        .onEnded { _ in lastScale = scale },
                    DragGesture()
                        .onChanged { v in offset = CGSize(width: lastOffset.width + v.translation.width, height: lastOffset.height + v.translation.height) }
                        .onEnded { _ in lastOffset = offset }
                )
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    scale = 2.0; offset = .zero; lastScale = 2.0; lastOffset = .zero
                }
            }
        }
        .onAppear { viewModel.loadPanoramaData() }
    }

    private var bgColor: Color { colorScheme == .dark ? ZenColor.darkBackground : ZenColor.ricePaperDeep }
    private func ringR(_ i: Int, maxR: CGFloat) -> CGFloat { [0.20, 0.36, 0.52, 0.68][i] * maxR }
}

// MARK: - 环内容层（使用 offset 定位）
struct RingItemsLayer: View {
    let rings: [RingData]
    let centerX: CGFloat; let centerY: CGFloat; let maxR: CGFloat

    var body: some View {
        ForEach(0..<min(rings.count, 4), id: \.self) { ringIdx in
            let r = ringR(ringIdx)
            let items = rings[ringIdx].items
            ForEach(0..<items.count, id: \.self) { itemIdx in
                let a = angle(itemIdx, total: items.count)
                Text(items[itemIdx].label)
                    .font(.system(size: 9))
                    .foregroundColor(items[itemIdx].color.opacity(0.85))
                    .fixedSize()
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(items[itemIdx].color.opacity(0.08))
                    .cornerRadius(4)
                    .offset(x: r * CGFloat(cos(a)), y: r * CGFloat(sin(a)))
            }
        }
    }
    private func ringR(_ i: Int) -> CGFloat { [0.20, 0.36, 0.52, 0.68][i] * maxR }
    private func angle(_ i: Int, total: Int) -> Double {
        total > 0 ? Double(i) / Double(total) * 2 * .pi - .pi / 2 : 0
    }
}

// MARK: - 中心
struct CoreView: View {
    let text: String; let sub: String; let radius: CGFloat
    @Environment(\.colorScheme) private var cs

    var body: some View {
        VStack(spacing: 2) {
            Text(text).font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(cs == .dark ? ZenColor.darkText : ZenColor.inkDark)
            Text(sub).font(.system(size: 9)).foregroundColor(.themeTextTertiary).lineLimit(1)
                .multilineTextAlignment(.center).frame(width: radius * 2.5)
        }
        .frame(width: radius * 2, height: radius * 2)
        .background(Circle().fill(RadialGradient(
            colors: [ZenColor.gold.opacity(0.22), ZenColor.gold.opacity(0.03), .clear],
            center: .center, startRadius: radius * 0.25, endRadius: radius * 1.3)))
    }
}
