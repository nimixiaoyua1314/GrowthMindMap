import SwiftUI

struct MissionCardView: View {
    let mission: String
    @Environment(\.colorScheme) private var cs
    @State private var isVisible = false

    private var accentColor: Color { cs == .dark ? ZenColor.gold : Color.themeSecondary }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "compass.drawing").font(.title3).foregroundColor(accentColor)
                Text("人生使命").font(.headline).foregroundColor(.themeTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                Text("\u{201C}").font(.system(size: 40, weight: .light)).foregroundColor(accentColor.opacity(0.5)).offset(y: -10)
                Text(mission).font(.body).fontWeight(.medium).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center).lineSpacing(6).padding(.horizontal, 4)
                Text("\u{201D}").font(.system(size: 40, weight: .light)).foregroundColor(accentColor.opacity(0.5)).offset(y: 10)
            }

            Text("基于你的经历和日记推断的方向，随成长演变")
                .font(.caption2).foregroundColor(.themeTextTertiary).multilineTextAlignment(.center)
        }
        .padding()
        .background(
            ZStack {
                Color.themeSurface
                Circle().fill(accentColor.opacity(0.06)).frame(width: 120, height: 120).offset(x: -100, y: -30).blur(radius: 10)
            }
        )
        .cornerRadius(16)
        .shadow(color: accentColor.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0).offset(y: isVisible ? 0 : 20)
        .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.3)) { isVisible = true } }
    }
}
