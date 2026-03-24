import Foundation

class ProfileViewModel {
    private let user: UserProfile
    
    let name: String
    let displayRedId: String
    let bio: String
    let avatarName: String
    let bgName: String
    
    // 格式化后的统计数据
    var stats: [(count: String, title: String)] {
        return [
            (format(user.followingCount), "关注"),
            (format(user.followerCount), "粉丝"),
            (format(user.collectCount), "获赞与收藏")
        ]
    }
    
    init(user: UserProfile) {
        self.user = user
        self.name = user.name
        self.displayRedId = "小红书号：\(user.redId)"
        self.bio = user.bio.isEmpty ? "点击添加简介" : user.bio
        self.avatarName = user.avatarName
        self.bgName = user.bgImageName
    }
    
    private func format(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        }
        return "\(count)"
    }
}
