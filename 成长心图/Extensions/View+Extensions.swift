import SwiftUI

// MARK: - 卡片样式修饰器
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? ZenColor.darkSurface : Color.themeSurface)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.06), radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - 禅意卡片样式
struct ZenCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(ZenColorScheme.surface(for: colorScheme))
            .cornerRadius(14)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.03), radius: 6, x: 0, y: 1)
    }
}

// MARK: - 水墨阴影
struct InkShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.1 : 0.02), radius: 2, x: 0, y: 0)
    }
}

// MARK: - 禅意背景
struct ZenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(ZenColorScheme.background(for: colorScheme))
    }
}

// MARK: - 毛玻璃卡片样式
struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
}

// MARK: - 标题样式
struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.themeTextPrimary)
    }
}

struct SubtitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(.themeTextSecondary)
    }
}

// MARK: - View 扩展
extension View {
    func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 4) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }

    func glassCardStyle() -> some View {
        modifier(GlassCardStyle())
    }

    func titleStyle() -> some View {
        modifier(TitleStyle())
    }

    func subtitleStyle() -> some View {
        modifier(SubtitleStyle())
    }

    // 禅意修饰器
    func zenCardStyle() -> some View {
        modifier(ZenCardStyle())
    }

    func inkShadow() -> some View {
        modifier(InkShadowModifier())
    }

    func zenBackground() -> some View {
        modifier(ZenBackgroundModifier())
    }

    /// 条件修饰器
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - 隐藏键盘
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
