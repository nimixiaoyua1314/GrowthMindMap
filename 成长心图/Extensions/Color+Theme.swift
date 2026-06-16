import SwiftUI

// MARK: - 应用主题色
extension Color {
    // 主色调
    static let themePrimary = Color(hex: "6B5B9A")       // 深紫 — 智慧
    static let themeSecondary = Color(hex: "F4A261")     // 暖橙 — 活力
    static let themeAccent = Color(hex: "E76F51")        // 珊瑚 — 热情

    // 背景色 — 暗色模式自动切换
    static let themeTextPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "F2F0EC") : UIColor(hex: "2D2D2D")
    })
    static let themeTextSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "C0BDB8") : UIColor(hex: "6B6B6B")
    })
    static let themeTextTertiary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "8A8D96") : UIColor(hex: "9B9B9B")
    })

    // 背景色 — 暗色模式自动切换
    static let themeSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1A1D28") : UIColor(hex: "FFFFFF")
    })
    static let themeBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "0F111A") : UIColor(hex: "FAF7F2")
    })

    // 功能色
    static let themeSuccess = Color(hex: "4CAF50")
    static let themeWarning = Color(hex: "FF9800")
    static let themeError = Color(hex: "F44336")
    static let themeInfo = Color(hex: "2196F3")

    // 情绪色
    static let moodExcellent = Color(hex: "FFD93D")      // 极好 — 明黄
    static let moodGood = Color(hex: "6BCB77")           // 好 — 翠绿
    static let moodNeutral = Color(hex: "4D96FF")        // 一般 — 蓝
    static let moodBad = Color(hex: "FF8C42")            // 不好 — 橙
    static let moodTerrible = Color(hex: "E76F51")       // 很差 — 珊瑚

    // 渐变
    static let gradientPrimary = LinearGradient(
        colors: [Color(hex: "7B6BAA"), Color(hex: "5B4B8A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientWarm = LinearGradient(
        colors: [Color(hex: "F4A261"), Color(hex: "E76F51")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex 初始化
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor hex init
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

// MARK: - ShapeStyle 扩展
extension ShapeStyle where Self == Color {
    static var themePrimary: Color { Color.themePrimary }
    static var themeSecondary: Color { Color.themeSecondary }
    static var themeBackground: Color { Color.themeBackground }
    static var themeSurface: Color { Color.themeSurface }
    static var themeTextPrimary: Color { Color.themeTextPrimary }
    static var themeTextSecondary: Color { Color.themeTextSecondary }
}
