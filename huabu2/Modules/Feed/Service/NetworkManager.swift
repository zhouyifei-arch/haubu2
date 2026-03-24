import Foundation
import Moya

// MARK: - 聚合API最外层结构
struct JuheResponse<T: Codable>: Codable {
    let reason: String
    let result: T?
    let error_code: Int
}

// MARK: - 修正后的新闻列表结构 (匹配 newslist)
struct NewsListData: Codable {
    let newslist: [FeedPost] // 🔴 关键：JSON 里叫 newslist
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let provider = MoyaProvider<NewsService>()
    
    func fetchNews(completion: @escaping ([FeedPost]) -> Void) {
        provider.request(.esports) { result in
            switch result {
            case .success(let response):
                do {
                    // 解析全路径：JuheResponse -> NewsListData -> [FeedPost]
                    let decodedResponse = try response.map(JuheResponse<NewsListData>.self)
                    
                    if decodedResponse.error_code == 0 {
                        let list = decodedResponse.result?.newslist ?? []
                        completion(list)
                    } else {
                        print("⚠️ 业务错误: \(decodedResponse.reason)")
                        completion([])
                    }
                } catch {
                    print("❌ 解析失败: \(error)")
                    completion([])
                }
            case .failure(let error):
                print("❌ 请求失败: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}
