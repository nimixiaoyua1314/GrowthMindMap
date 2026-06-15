import SwiftUI

struct MainTabView: View {
    @StateObject private var recordVM: RecordViewModel
    @StateObject private var analysisVM: AnalysisViewModel
    @StateObject private var suggestionVM: SuggestionViewModel
    @StateObject private var panoramaVM: PanoramaViewModel
    @State private var selectedTab = 0

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

            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(ZenColor.ricePaper)

            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(ZenColor.inkLight)
            itemAppearance.selected.iconColor = UIColor(ZenColor.gold)
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 { panoramaVM.loadPanoramaData() }
            if newTab == 1 { recordVM.fetchAll() }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
