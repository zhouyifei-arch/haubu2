import UIKit
import SnapKit
import MJRefresh
import RealmSwift

class FeedViewController: UIViewController {
    
    // MARK: - Properties
    private var posts: [FeedPost] = []
    private var isEditingMode = false // 控制是否处于删除模式
    
    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        cv.register(FeedCell.self, forCellWithReuseIdentifier: "FeedCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "社区"
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupUI()
        setupRefresh()
        setupNotifications()
        setupGestures() // 🔴 新增：初始化手势
        
        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        let postItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapPostButton))
        self.navigationItem.rightBarButtonItem = postItem
    }

    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupRefresh() {
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.exitEditingMode() // 刷新时自动退出编辑模式
            self?.loadData()
        })
        header.lastUpdatedTimeLabel?.isHidden = true
        header.stateLabel?.isHidden = true
        header.isAutomaticallyChangeAlpha = true
        collectionView.mj_header = header
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRefreshNotification),
                                               name: NSNotification.Name("DidPostNewContent"),
                                               object: nil)
    }

    // 🔴 新增：手势设置
    private func setupGestures() {
        // 1. 长按手势：进入编辑模式
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)
        
        // 2. 点击手势：点击背景退出编辑模式
        let tap = UITapGestureRecognizer(target: self, action: #selector(exitEditingMode))
        tap.cancelsTouchesInView = false // 确保不影响 Cell 的正常点击跳转
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Actions
    @objc private func didTapPostButton() {
        exitEditingMode()
        let createVC = CreatePostViewController()
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func handleRefreshNotification() {
        print("📥 收到发布成功通知，开始刷新列表...")
        self.loadData()
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began && !isEditingMode {
            isEditingMode = true
            UISelectionFeedbackGenerator().selectionChanged() // 震动反馈
            collectionView.reloadData()
        }
    }

    @objc private func exitEditingMode() {
        if isEditingMode {
            isEditingMode = false
            collectionView.reloadData()
        }
    }
    
    // MARK: - Data Logic
    private func loadData() {
        let realm = try! Realm()
        
        // 1. 获取本地所有数据（含缓存）
        let allPosts = realm.objects(FeedPost.self).sorted(byKeyPath: "ctime", ascending: false)
        self.posts = Array(allPosts)
        collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
        
        // 2. 网络请求
        NetworkManager.shared.fetchNews { [weak self] networkList in
            DispatchQueue.main.async {
                guard let self = self else { return }
                do {
                    let realm = try Realm()
                    try realm.write {
                        for post in networkList {
                            // 确保 PrimaryKey 不为空，防止写入失败
                            if post.id == nil { post.id = post.url ?? UUID().uuidString }
                            realm.add(post, update: .all)
                        }
                    }
                } catch {
                    print("❌ Realm 写入失败: \(error)")
                }
                
                let updatedPosts = realm.objects(FeedPost.self).sorted(byKeyPath: "ctime", ascending: false)
                self.posts = Array(updatedPosts)
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.reloadData()
                self.collectionView.mj_header?.endRefreshing()
            }
        }
    }

    // 🔴 新增：执行删除逻辑
    private func performDelete(post: FeedPost) {
        guard post.isLocal else { return }
        guard let postID = post.id, let index = posts.firstIndex(where: { $0.id == postID }) else {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            return
        }

        do {
            let realm = try Realm()
            // 找到数据库中对应的对象
            if let objectToDelete = realm.object(ofType: FeedPost.self, forPrimaryKey: postID) {
                try realm.write {
                    realm.delete(objectToDelete)
                }
                // 更新 UI
                self.posts.remove(at: index)
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        } catch {
            print("❌ 删除失败: \(error)")
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate & WaterfallDelegate
extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegate, WaterfallLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as! FeedCell
        let post = posts[indexPath.item]
        cell.configure(with: post)
        
        // 🔴 关键：设置删除模式状态
        cell.showDeleteButton(isEditingMode, canDelete: post.isLocal)
        
        // 🔴 关键：绑定删除闭包
        cell.deleteAction = { [weak self] in
            let alert = UIAlertController(title: "提示", message: "确定删除这条动态吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
                self?.performDelete(post: post)
            })
            self?.present(alert, animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, columnWidth: CGFloat) -> CGFloat {
        return columnWidth * 1.3 + 55
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 如果在编辑模式，点击 Cell 则是退出模式，不跳转详情
        if isEditingMode {
            exitEditingMode()
            return
        }
        
        let post = posts[indexPath.item]
        let detailVC = FeedDetailViewController(post: post)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
