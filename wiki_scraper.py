#!/usr/bin/env python3
"""
维基百科爬虫 — 根据用户兴趣生成时空词条
用法: python3 wiki_scraper.py [interests_json_path]
输出: 成长心图/Resources/wiki_terms.json
"""

import json
import urllib.request
import urllib.parse
import os
import sys
import time
import ssl
from datetime import datetime

# 跳过 SSL 验证（部分网络环境需要）
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

# 用户兴趣关键词（从分析引擎获取，也可通过命令行传入 JSON 文件）
DEFAULT_INTERESTS = {
    "traits": ["创造力", "好奇心", "分析力"],
    "categories": ["教育", "科技"],
    "topics": ["人工智能", "可持续发展", "心理学"],
}

WIKI_API = "https://zh.wikipedia.org/w/api.php"

def wiki_search(query, limit=5):
    """搜索维基百科"""
    params = {
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srlimit": limit,
        "format": "json",
    }
    url = WIKI_API + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "GrowthMindMap/1.0"})
        with urllib.request.urlopen(req, timeout=15, context=ssl_ctx) as resp:
            data = json.loads(resp.read())
            return [r["title"] for r in data.get("query", {}).get("search", [])]
    except Exception as e:
        print(f"  ⚠️  搜索 '{query}' 失败: {e}")
        return []

def wiki_extract(title, sentences=3):
    """提取页面摘要"""
    params = {
        "action": "query",
        "prop": "extracts",
        "exintro": 1,
        "explaintext": 1,
        "exsentences": sentences,
        "titles": title,
        "format": "json",
    }
    url = WIKI_API + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "GrowthMindMap/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            pages = data.get("query", {}).get("pages", {})
            for p in pages.values():
                return p.get("extract", "")
    except Exception:
        pass
    return ""

def build_terms(interests):
    """根据用户兴趣构建时空词条"""
    result = {
        "generated_at": datetime.now().isoformat(),
        "history": [],      # 历史：基础概念、学科奠基
        "present": [],      # 当下：近年发展、热点
        "future": [],       # 未来：趋势、前沿
    }

    traits = interests.get("traits", [])
    categories = interests.get("categories", [])
    topics = interests.get("topics", [])

    all_keywords = traits + categories + topics
    print(f"🔍 搜索关键词: {all_keywords}")

    # 历史 — 搜索"XX的历史"或"XX起源"
    history_queries = [f"{kw} 历史" for kw in all_keywords[:4]]
    history_queries += [f"{kw} 起源" for kw in categories[:2]]

    for q in history_queries[:6]:
        print(f"  📜 历史: {q}")
        titles = wiki_search(q, limit=2)
        for t in titles:
            result["history"].append({"term": t, "source": q})
        time.sleep(0.3)

    # 当下 — 搜索"2025 XX"或直接搜关键词
    present_queries = [f"2025 {kw}" for kw in topics[:3]]
    present_queries += [kw for kw in topics[:3]]

    for q in present_queries[:6]:
        print(f"  📰 当下: {q}")
        titles = wiki_search(q, limit=2)
        for t in titles:
            result["present"].append({"term": t, "source": q})
        time.sleep(0.3)

    # 未来 — 搜索"XX发展趋势"或"XX前景"
    future_queries = [f"{kw} 发展趋势" for kw in topics[:3]]
    future_queries += [f"{kw} 未来" for kw in categories[:2]]
    future_queries += ["人工智能 未来 趋势", "可持续发展 前景"]

    for q in future_queries[:6]:
        print(f"  🔮 未来: {q}")
        titles = wiki_search(q, limit=2)
        for t in titles:
            result["future"].append({"term": t, "source": q})
        time.sleep(0.3)

    # 去重
    for key in ["history", "present", "future"]:
        seen = set()
        unique = []
        for item in result[key]:
            if item["term"] not in seen:
                seen.add(item["term"])
                unique.append(item)
        result[key] = unique

    return result

def main():
    interests = DEFAULT_INTERESTS

    # 从命令行参数读取
    if len(sys.argv) > 1:
        try:
            with open(sys.argv[1], "r") as f:
                interests = json.load(f)
        except Exception as e:
            print(f"读取配置失败: {e}，使用默认值")

    print("=" * 50)
    print("🌐 成长心图 — 维基百科时空词条爬虫")
    print(f"   用户兴趣: {interests}")
    print("=" * 50)

    terms = build_terms(interests)

    # 输出路径
    output_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(output_dir, "成长心图", "Resources", "wiki_terms.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(terms, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 词条已保存: {output_path}")
    print(f"   历史: {len(terms['history'])} 条")
    print(f"   当下: {len(terms['present'])} 条")
    print(f"   未来: {len(terms['future'])} 条")

if __name__ == "__main__":
    main()
