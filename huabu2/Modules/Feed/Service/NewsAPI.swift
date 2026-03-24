import Foundation
import Moya
import Alamofire
enum NewsService {
    case esports
}

extension NewsService: TargetType {
    // 🔴 尝试切换为 https，并确保域名后没有任何斜杠
    var baseURL: URL {
        return URL(string: "https://apis.juhe.cn")!
    }
    
    // 🔴 路径开头必须带斜杠，结尾绝对不能带斜杠
    var path: String {
        return "/fapigx/esports/query"
    }
    
    var method: Moya.Method { return .get }
    
    var task: Task {
        // 🔴 重新采用传参模式，但强制指定参数放在 URL 后面（QueryString）
        // 这样可以避免路径过长导致的 10022 错误
        return .requestParameters(
            parameters: ["key": "1a049ebd602fb106a45cd954dabfdaa6"],
            encoding: URLEncoding(destination: .queryString)
        )
    }
    
    var headers: [String: String]? {
        // 🔴 保持为 nil，防止协议头冲突
        return nil
    }
}
