import SwiftUI

struct PanoramaView: View {
    @ObservedObject var viewModel: PanoramaViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var ambient = AmbientSoundEngine()
    var onNavigate: ((Int) -> Void)?

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let r1 = w * 0.35
            let r2 = w * 0.28
            let cx = w / 2
            let c1y = h * 0.30
            let c2y = c1y + r1 + r2 + 8

            ZStack {
                bgColor.ignoresSafeArea()

                Group {
                    MyCircle(
                        rings: viewModel.rings,
                        centerX: cx, centerY: c1y, maxR: r1,
                        radii: [0.22, 0.40, 0.58, 0.76],
                        ringColors: [ZenColor.gold, ZenColor.vermilionLight, ZenColor.jade, Color.themeInfo],
                        core: viewModel.centerText, coreSub: viewModel.centerSub
                    )
                    TimelineCircle(
                        rings: viewModel.timelineRings,
                        centerX: cx, centerY: c2y, maxR: r2,
                        radii: [0.28, 0.56, 0.84],
                        ringColors: [ZenColor.inkLight, ZenColor.vermilion, Color.themeInfo],
                        core: "时空", coreSub: ""
                    )
                    // 切点
                    Circle().fill(ZenColor.gold.opacity(0.15)).frame(width: 5, height: 5).position(x: cx, y: c1y + r1)
                    Circle().fill(ZenColor.gold.opacity(0.10)).frame(width: 4, height: 4).position(x: cx, y: c2y - r2)
                }
                .scaleEffect(scale).offset(offset)

                // 音乐
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            ambient.isPlaying ? ambient.stop() : ambient.start()
                        } label: {
                            Image(systemName: ambient.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 13))
                                .foregroundColor(ambient.isPlaying ? ZenColor.gold : ZenColor.inkPale)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { v in scale = min(max(lastScale * v, 0.4), 4.0) }
                        .onEnded { _ in lastScale = scale },
                    DragGesture()
                        .onChanged { v in
                            offset = CGSize(
                                width: lastOffset.width + v.translation.width,
                                height: lastOffset.height + v.translation.height
                            )
                        }
                        .onEnded { _ in lastOffset = offset }
                )
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    scale = 1.0; offset = .zero; lastScale = 1.0; lastOffset = .zero
                }
            }
        }
        .onAppear { viewModel.loadPanoramaData() }
    }

    private var bgColor: Color {
        colorScheme == .dark ? ZenColor.darkBackground : ZenColor.ricePaperDeep
    }
}

// MARK: - 圆1: 我
struct MyCircle: View {
    let rings: [RingData]
    let centerX: CGFloat; let centerY: CGFloat
    let maxR: CGFloat; let radii: [CGFloat]
    let ringColors: [Color]
    let core: String; let coreSub: String

    var body: some View {
        let cnt = min(rings.count, radii.count)
        let coreR = radii[0] * maxR * 0.65

        ZStack {
            ForEach(0..<cnt, id: \.self) { i in
                let r = radii[i] * maxR
                Circle()
                    .stroke(ringColors[i].opacity(0.13), lineWidth: 1)
                    .frame(width: r * 2, height: r * 2)
                    .position(x: centerX, y: centerY)
                Circle()
                    .fill(ringColors[i].opacity(0.025))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: centerX, y: centerY)

                Text(rings[i].title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(ZenColor.inkLight.opacity(0.45))
                    .position(x: centerX, y: centerY - r - 7)
            }

            ForEach(0..<cnt, id: \.self) { i in
                let r = radii[i] * maxR
                ForEach(rings[i].items.indices, id: \.self) { j in
                    let total = rings[i].items.count
                    let angle = total > 0 ? Double(j) / Double(total) * 2 * .pi - .pi / 2 : 0.0
                    let dx = r * CGFloat(cos(angle))
                    let dy = r * CGFloat(sin(angle))
                    Text(rings[i].items[j].label)
                        .font(.system(size: 7))
                        .foregroundColor(rings[i].items[j].color.opacity(0.8))
                        .fixedSize()
                        .padding(.horizontal, 3).padding(.vertical, 1)
                        .background(rings[i].items[j].color.opacity(0.06))
                        .cornerRadius(3)
                        .position(x: centerX + dx, y: centerY + dy)
                }
            }

            VStack(spacing: 0) {
                Text(core)
                    .font(.system(size: coreR > 28 ? 15 : 12, weight: .medium, design: .serif))
                    .foregroundColor(.themeTextPrimary)
                if !coreSub.isEmpty {
                    Text(coreSub)
                        .font(.system(size: 6))
                        .foregroundColor(.themeTextTertiary)
                        .lineLimit(1)
                        .frame(width: coreR * 2.2)
                }
            }
            .frame(width: coreR * 2, height: coreR * 2)
            .background(
                Circle().fill(
                    RadialGradient(
                        colors: [ZenColor.gold.opacity(0.18), ZenColor.gold.opacity(0.02), .clear],
                        center: .center, startRadius: coreR * 0.2, endRadius: coreR * 1.2
                    )
                )
            )
            .position(x: centerX, y: centerY)
        }
    }
}

// MARK: - 圆2: 时空
struct TimelineCircle: View {
    let rings: [RingData]
    let centerX: CGFloat; let centerY: CGFloat
    let maxR: CGFloat; let radii: [CGFloat]
    let ringColors: [Color]
    let core: String; let coreSub: String

    var body: some View {
        let cnt = min(rings.count, radii.count)
        let coreR = radii[0] * maxR * 0.65

        ZStack {
            ForEach(0..<cnt, id: \.self) { i in
                let r = radii[i] * maxR
                Circle()
                    .stroke(ringColors[i].opacity(0.13), lineWidth: 1)
                    .frame(width: r * 2, height: r * 2)
                    .position(x: centerX, y: centerY)
                Circle()
                    .fill(ringColors[i].opacity(0.025))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: centerX, y: centerY)

                Text(rings[i].title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(ZenColor.inkLight.opacity(0.45))
                    .position(x: centerX, y: centerY - r - 7)
            }

            ForEach(0..<cnt, id: \.self) { i in
                let r = radii[i] * maxR
                ForEach(rings[i].items.indices, id: \.self) { j in
                    let total = rings[i].items.count
                    let angle = total > 0 ? Double(j) / Double(total) * 2 * .pi - .pi / 2 : 0.0
                    let dx = r * CGFloat(cos(angle))
                    let dy = r * CGFloat(sin(angle))
                    Text(rings[i].items[j].label)
                        .font(.system(size: 7))
                        .foregroundColor(rings[i].items[j].color.opacity(0.8))
                        .fixedSize()
                        .padding(.horizontal, 3).padding(.vertical, 1)
                        .background(rings[i].items[j].color.opacity(0.06))
                        .cornerRadius(3)
                        .position(x: centerX + dx, y: centerY + dy)
                }
            }

            VStack(spacing: 0) {
                Text(core)
                    .font(.system(size: coreR > 28 ? 15 : 12, weight: .medium, design: .serif))
                    .foregroundColor(.themeTextPrimary)
                if !coreSub.isEmpty {
                    Text(coreSub)
                        .font(.system(size: 6))
                        .foregroundColor(.themeTextTertiary)
                        .lineLimit(1)
                        .frame(width: coreR * 2.2)
                }
            }
            .frame(width: coreR * 2, height: coreR * 2)
            .background(
                Circle().fill(
                    RadialGradient(
                        colors: [ZenColor.gold.opacity(0.18), ZenColor.gold.opacity(0.02), .clear],
                        center: .center, startRadius: coreR * 0.2, endRadius: coreR * 1.2
                    )
                )
            )
            .position(x: centerX, y: centerY)
        }
    }
}
