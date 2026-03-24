import Foundation
import RealmSwift
import Realm
class FeedPost: Object, Codable {
    @Persisted(primaryKey: true) var id: String?
    @Persisted var ctime: String?
    @Persisted var title: String?
    @Persisted var source: String?
    @Persisted var pic: String?
    @Persisted var url: String?
    @Persisted var isLocal: Bool = false
    // 🔴 确保这里定义了 desc
    @Persisted var desc: String?

    enum CodingKeys: String, CodingKey {
        case id, ctime, title, source, url
        case pic = "picUrl"
        // 🔴 确保 JSON 里的 "description" 映射给了代码里的 "desc"
        case desc = "description"
    }
}
