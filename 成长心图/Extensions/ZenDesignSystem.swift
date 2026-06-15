import SwiftUI

// MARK: - 禅意色彩系统
struct ZenColor {
    // 背景 — 宣纸/墨色
    static let ricePaper = Color(hex: "F5F0E8")
    static let ricePaperDeep = Color(hex: "EDE8DC")
    static let inkBlack = Color(hex: "1A1512")
    static let inkDark = Color(hex: "2C2416")
    static let inkMedium = Color(hex: "5C5344")
    static let inkLight = Color(hex: "8A8175")
    static let inkPale = Color(hex: "B5AFA5")

    // 金色光 — 古铜金
    static let gold = Color(hex: "C9A96E")
    static let goldLight = Color(hex: "DDC896")
    static let goldPale = Color(hex: "EDE0C0")
    static let goldDeep = Color(hex: "A8884A")

    // 翡翠/禅绿
    static let jade = Color(hex: "6B8F71")
    static let jadeLight = Color(hex: "8BAF91")
    static let jadePale = Color(hex: "D0E0D3")

    // 朱砂点缀
    static let vermilion = Color(hex: "B8705A")
    static let vermilionLight = Color(hex: "CC9080")
    static let vermilionPale = Color(hex: "E8D0C8")

    // 暗黑模式 — 深蓝黑底
    static let darkBackground = Color(hex: "0F111A")
    static let darkSurface = Color(hex: "1A1D28")
    static let darkText = Color(hex: "E4E2DD")
    static let darkTextSecondary = Color(hex: "8A8D96")
}

// MARK: - ShapeStyle 便捷扩展
extension ShapeStyle where Self == Color {
    static var zenRicePaper: Color { ZenColor.ricePaper }
    static var zenInk: Color { ZenColor.inkDark }
    static var zenGold: Color { ZenColor.gold }
    static var zenJade: Color { ZenColor.jade }
    static var zenVermilion: Color { ZenColor.vermilion }
}

// MARK: - 禅意阴影预设
struct ZenShadow {
    /// 柔和纸张阴影
    static let soft = (color: Color.black.opacity(0.04), radius: CGFloat(8), y: CGFloat(2))

    /// 悬浮卡片阴影
    static let elevated = (color: Color.black.opacity(0.06), radius: CGFloat(16), y: CGFloat(4))

    /// 金色光晕
    static let goldGlow = (color: ZenColor.gold.opacity(0.25), radius: CGFloat(20), y: CGFloat(0))

    /// 核心呼吸光晕
    static let coreBreath = (color: ZenColor.gold.opacity(0.35), radius: CGFloat(30), y: CGFloat(0))
}

// MARK: - 禅意动效常量
enum ZenAnimation {
    /// 呼吸周期 (秒)
    static let breathDuration: Double = 4.0

    /// 环入场 stagger 间隔
    static let ringStagger: Double = 0.25

    /// 环入场总时长
    static let ringRevealDuration: Double = 0.9

    /// 涟漪扩散时长
    static let rippleDuration: Double = 0.8

    /// 粒子漂浮速度
    static let particleDriftSpeed: Double = 0.4

    /// 标准缓动
    static let easeOut = Animation.easeOut(duration: 0.6)
    static let easeInOut = Animation.easeInOut(duration: 0.7)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - 禅意字体预设
struct ZenTypography {
    /// 大标题 — 篆刻感
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// 正文
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// 数字/数据
    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    /// 标签文字
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// MARK: - 环境色感知
enum ZenColorScheme {
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ZenColor.darkBackground : ZenColor.ricePaper
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ZenColor.darkSurface : Color(hex: "FAFAF6")
    }

    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ZenColor.darkText : ZenColor.inkDark
    }

    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ZenColor.darkTextSecondary : ZenColor.inkLight
    }
}
