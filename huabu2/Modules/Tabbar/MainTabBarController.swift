import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBarAppearance()
    }
    
    private func setupViewControllers() {
        // 1. 社区页 - 瀑布流展示
        let feedVC = FeedViewController()
        feedVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "square.grid.2x2"), tag: 0)
        let feedNav = UINavigationController(rootViewController: feedVC)
        
        // 2. 编辑页 - 原有的发布功能
        let editorVC = EditorViewController()
        editorVC.tabBarItem = UITabBarItem(title: "Post", image: UIImage(systemName: "plus.circle"), tag: 1)
        let editorNav = UINavigationController(rootViewController: editorVC)
        
        // 3. AI 抠图页 - 新增的图像分割功能 (使用 SnapKit 布局那个类)
        let segmentationVC = ImageSegmentationViewController()
        segmentationVC.tabBarItem = UITabBarItem(title: "Magic", image: UIImage(systemName: "scissors"), tag: 2)
        let segNav = UINavigationController(rootViewController: segmentationVC)
        
        // 4. 个人页 - 包含 Realm 数据展示
        let profileVC = ProfileViewController()
        // 注入你的 Mock 数据和 ViewModel
        let mockUser = UserProfile(
            name: "ZJS",
            redId: "102456789",
            bio: "保持热爱，奔赴山海。",
            avatarName: "my_avatar_image",
            bgImageName: "my_bg_image",
            followingCount: 158,
            followerCount: 12500,
            collectCount: 88000
        )
        profileVC.viewModel = ProfileViewModel(user: mockUser)
        profileVC.tabBarItem = UITabBarItem(title: "Me", image: UIImage(systemName: "person"), tag: 3)
        let profileNav = UINavigationController(rootViewController: profileVC)
        
        // 将四个模块注入 TabBar
        viewControllers = [feedNav, editorNav, segNav, profileNav]
    }
    
    private func setupTabBarAppearance() {
        // 设置 TabBar 样式
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .systemPurple      // 选中颜色
        tabBar.unselectedItemTintColor = .gray // 未选中颜色
        
        // 如果需要毛玻璃效果或自定义边框线，可以在这里配置
        tabBar.isTranslucent = true
    }
}
