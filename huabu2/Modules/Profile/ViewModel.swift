import Foundation

class ProfileViewModel {
    private var user: UserProfile
    
    private(set) var name: String
    let displayRedId: String
    private(set) var bio: String
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
    
    func update(name: String, bio: String) {
        user = UserProfile(
            name: name,
            redId: user.redId,
            bio: bio,
            avatarName: user.avatarName,
            bgImageName: user.bgImageName,
            followingCount: user.followingCount,
            followerCount: user.followerCount,
            collectCount: user.collectCount
        )
        self.name = user.name
        self.bio = user.bio.isEmpty ? "点击添加简介" : user.bio
    }
    
    private func format(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        }
        return "\(count)"
    }
}
