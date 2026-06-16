import Foundation

/// 维基百科词条数据结构
struct WikiTerms: Codable {
    let generatedAt: String
    let history: [WikiTerm]
    let present: [WikiTerm]
    let future: [WikiTerm]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case history, present, future
    }
}

struct WikiTerm: Codable {
    let term: String
    let source: String
}

/// 加载 wiki_terms.json
final class WikiTermsService {
    static let shared = WikiTermsService()

    private var cached: WikiTerms?

    func load() -> WikiTerms {
        if let c = cached { return c }

        // 1. 尝试从 bundle 加载
        if let url = Bundle.main.url(forResource: "wiki_terms", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let terms = try JSONDecoder().decode(WikiTerms.self, from: data)
                cached = terms
                return terms
            } catch {
                print("WikiTerms: bundle load failed: \(error)")
            }
        }

        // 2. 尝试从文件系统加载（开发模式）
        let devPath = "/Volumes/拓展空间/成长心图/成长心图/Resources/wiki_terms.json"
        if FileManager.default.fileExists(atPath: devPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: devPath))
                let terms = try JSONDecoder().decode(WikiTerms.self, from: data)
                cached = terms
                return terms
            } catch {
                print("WikiTerms: dev path load failed: \(error)")
            }
        }

        // 3. 返回空数据
        return WikiTerms(generatedAt: "", history: [], present: [], future: [])
    }

    /// 刷新缓存
    func reload() {
        cached = nil
        _ = load()
    }
}
