import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var recordVM: RecordViewModel
    @StateObject private var analysisVM: AnalysisViewModel
    @StateObject private var suggestionVM: SuggestionViewModel
    @StateObject private var panoramaVM: PanoramaViewModel
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("colorScheme") private var storedColorScheme: String = "system"

    init() {
        let context = PersistenceController.shared.container.viewContext
        _recordVM = StateObject(wrappedValue: RecordViewModel(context: context))
        _analysisVM = StateObject(wrappedValue: AnalysisViewModel(context: context))
        _suggestionVM = StateObject(wrappedValue: SuggestionViewModel(context: context))
        _panoramaVM = StateObject(wrappedValue: PanoramaViewModel(context: context))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: 全景
            PanoramaView(viewModel: panoramaVM) { tabIndex in
                withAnimation { selectedTab = tabIndex }
            }
            .tabItem {
                Image(systemName: "circle.hexagongrid")
                Text("全景")
            }
            .tag(0)

            // Tab 1: 记录 (经历 + 日记 统一)
            NavigationStack {
                RecordView(viewModel: recordVM)
            }
            .tabItem {
                Image(systemName: "square.and.pencil")
                Text("记录")
            }
            .tag(1)

            // Tab 2: 分析
            NavigationStack {
                AnalysisView(viewModel: analysisVM, suggestionVM: suggestionVM)
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("分析")
            }
            .tag(2)

            // Tab 3: 我的 (含建议)
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person")
                Text("我的")
            }
            .tag(3)
        }
        .tint(ZenColor.gold)
        .onAppear {
            panoramaVM.loadPanoramaData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { updateTabBar() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            updateTabBar()
        }
        .onChange(of: storedColorScheme) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { updateTabBar() }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 { panoramaVM.loadPanoramaData() }
            if newTab == 1 { recordVM.fetchAll() }
        }
    }

    private func resolveIsDark() -> Bool {
        switch storedColorScheme {
        case "light": return false
        case "dark": return true
        default:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    private func updateTabBar() {
        let isDark = resolveIsDark()
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(isDark ? ZenColor.darkBackground : ZenColor.ricePaper)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(isDark ? ZenColor.darkTextSecondary : ZenColor.inkLight)
        itemAppearance.selected.iconColor = UIColor(ZenColor.gold)
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
