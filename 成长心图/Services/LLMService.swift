import Foundation

/// AI 深度分析服务（可选，用户需配置 API Key）
final class LLMService {
    /// API Key，用户可在设置中配置
    var apiKey: String {
        UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
    }

    var apiEndpoint: String {
        UserDefaults.standard.string(forKey: "llm_api_endpoint") ?? "https://api.anthropic.com/v1/messages"
    }

    /// AI 深度分析结果
    struct DeepAnalysisResult: Decodable {
        let mission: String
        let summary: String
        let strengthAreas: [String]
        let growthAreas: [String]
    }

    /// 发送深度分析请求
    func deepAnalyze(experienceSummary: String, diarySummary: String) async throws -> DeepAnalysisResult {
        guard !apiKey.isEmpty else {
            throw LLMError.noAPIKey
        }

        let prompt = buildPrompt(experiences: experienceSummary, diaries: diarySummary)

        // 构建 Claude API 请求
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 2048,
            "messages": [
                [
                    "role": "user",
                    "content": prompt,
                ],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "life_analysis",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "mission": ["type": "string", "description": "基于分析推断的人生使命"],
                            "summary": ["type": "string", "description": "300字以内的分析摘要"],
                            "strengthAreas": ["type": "array", "items": ["type": "string"], "description": "3个优势领域"],
                            "growthAreas": ["type": "array", "items": ["type": "string"], "description": "3个成长领域建议"],
                        ],
                        "required": ["mission", "summary", "strengthAreas", "growthAreas"],
                    ],
                ],
            ],
        ]

        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LLMError.requestFailed
        }

        // 解析响应
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let contentArray = json?["content"] as? [[String: Any]],
              let textBlock = contentArray.first(where: { ($0["type"] as? String) == "text" }),
              let text = textBlock["text"] as? String,
              let jsonData = text.data(using: .utf8) else {
            throw LLMError.parseFailed
        }

        return try JSONDecoder().decode(DeepAnalysisResult.self, from: jsonData)
    }

    private func buildPrompt(experiences: String, diaries: String) -> String {
        return """
        你是一位专业的心理学家和人生教练。请基于以下用户的经历和日记摘要，进行深度分析。

        ## 用户经历摘要：
        \(experiences)

        ## 用户日记摘要：
        \(diaries)

        ## 分析要求：
        请分析并输出JSON格式结果，包含：
        1. mission: 推断用户的人生使命（1-2句话，用中文）
        2. summary: 300字以内的分析摘要，包含用户的核心特质、情感模式和成长建议
        3. strengthAreas: 用户当前的优势领域（3个）
        4. growthAreas: 建议用户重点发展的领域（3个）

        请保持温暖、深刻、个性化的分析风格。
        """
    }
}

enum LLMError: LocalizedError {
    case noAPIKey
    case requestFailed
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "请先配置 AI API Key"
        case .requestFailed: return "AI 服务请求失败，请检查网络和 API Key"
        case .parseFailed: return "AI 响应解析失败，请重试"
        }
    }
}
