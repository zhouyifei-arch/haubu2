import UIKit
import SnapKit
import RealmSwift

class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    var viewModel: ProfileViewModel? {
        didSet { collectionView.reloadData() }
    }
    
    private var myPosts: [FeedPost] = []
    private var isEditingMode = false
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        
        // 注册 Cell
        cv.register(FeedCell.self, forCellWithReuseIdentifier: "FeedCell")
        // 注册 Header (注意这里改用 UICollectionReusableView)
        cv.register(UICollectionReusableView.self,
                   forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                   withReuseIdentifier: "ProfileHeader")
        
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMyPosts()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Layout Logic (修复警告的核心)
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (_, _) -> NSCollectionLayoutSection? in
            
            // 1. 定义 Item (作品卡片)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // ✅ 修复警告：使用 edgeSpacing 替代 contentInsets
            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: .fixed(5),
                top: .fixed(2),
                trailing: .fixed(5),
                bottom: .fixed(5)
            )
            
            // 2. 定义 Group (一行两个)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // 3. 定义 Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
            
            // ✅ 4. 添加真正的 Header (Profile 信息区)
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(330)
            )
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [headerItem]
            
            return section
        }
    }

    // MARK: - Data Logic
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name("DidPostNewContent"), object: nil)
    }
    
    @objc private func handleRefresh() {
        loadMyPosts()
    }

    private func loadMyPosts() {
        let realm = try! Realm()
        realm.refresh()
        let results = realm.objects(FeedPost.self).filter("isLocal == true").sorted(byKeyPath: "ctime", ascending: false)
        self.myPosts = Array(results)
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began && !isEditingMode {
            isEditingMode = true
            collectionView.reloadData()
        }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // 现在只有 1 个 Section
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myPosts.count
    }
    
    // 配置 Cell (仅限作品卡片)
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as! FeedCell
        let post = myPosts[indexPath.item]
        cell.configure(with: post)
        cell.showDeleteButton(isEditingMode)
        cell.deleteAction = { [weak self] in
            self?.confirmDelete(post: post, index: indexPath.item)
        }
        return cell
    }
    
    // ✅ 配置 Header (Profile 信息区)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileHeader", for: indexPath)
            setupProfileHeaderUI(on: header)
            return header
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            isEditingMode = false
            collectionView.reloadData()
            return
        }
        let detailVC = FeedDetailViewController(post: myPosts[indexPath.item])
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UI Rendering (Header)
extension ProfileViewController {
    private func setupProfileHeaderUI(on container: UIView) {
        // 防止复用时重复添加 View
        if let existingStack = container.viewWithTag(777) as? UIStackView {
            updateStats(existingStack)
            return
        }
        
        guard let vm = viewModel else { return }
        
        let bg = UIImageView()
        bg.image = UIImage(named: vm.bgName)
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        container.addSubview(bg)
        
        let avatar = UIImageView()
        avatar.image = UIImage(named: vm.avatarName) ?? UIImage(systemName: "person.circle.fill")
        avatar.layer.cornerRadius = 40
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = UIColor.white.cgColor
        avatar.clipsToBounds = true
        container.addSubview(avatar)
        
        let name = UILabel()
        name.text = vm.name
        name.font = .systemFont(ofSize: 22, weight: .bold)
        container.addSubview(name)
        
        let bio = UILabel()
        bio.text = vm.bio
        bio.font = .systemFont(ofSize: 14)
        bio.textColor = .secondaryLabel
        bio.numberOfLines = 2
        container.addSubview(bio)
        
        let stack = UIStackView()
        stack.tag = 777
        stack.axis = .horizontal
        stack.spacing = 25
        container.addSubview(stack)
        
        // SnapKit 布局
        bg.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalTo(bg.snp.bottom).offset(10)
            make.width.height.equalTo(80)
        }
        name.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(12)
            make.leading.equalTo(avatar)
        }
        bio.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(bio.snp.bottom).offset(15)
            make.leading.equalTo(bio)
            // Header 无需设置底部约束，它的高度由 Layout 中的 .absolute(330) 决定
        }
        
        updateStats(stack)
    }
    
    private func updateStats(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let vm = viewModel else { return }
        for stat in vm.stats {
            let label = UILabel()
            let count = (stat.title == "作品") ? "\(myPosts.count)" : stat.count
            label.text = "\(count) \(stat.title)"
            label.font = .systemFont(ofSize: 15, weight: .medium)
            stack.addArrangedSubview(label)
        }
    }
}

// MARK: - Delete Logic
extension ProfileViewController {
    private func confirmDelete(post: FeedPost, index: Int) {
        let alert = UIAlertController(title: "提示", message: "确定删除这条作品吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
            let realm = try! Realm()
            if let obj = realm.object(ofType: FeedPost.self, forPrimaryKey: post.id) {
                try! realm.write { realm.delete(obj) }
                self.loadMyPosts()
                NotificationCenter.default.post(name: NSNotification.Name("DidPostNewContent"), object: nil)
            }
        })
        present(alert, animated: true)
    }
}
