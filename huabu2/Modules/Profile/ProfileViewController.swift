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
    
    private enum ProfileStorageKeys {
        static let name = "profile.name"
        static let bio = "profile.bio"
        static let avatarPath = "profile.avatarPath"
        static let backgroundPath = "profile.backgroundPath"
    }
    
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
        applySavedProfileIfNeeded()
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
    
    private func applySavedProfileIfNeeded() {
        guard let vm = viewModel else { return }
        let savedName = UserDefaults.standard.string(forKey: ProfileStorageKeys.name)
        let savedBio = UserDefaults.standard.string(forKey: ProfileStorageKeys.bio)
        if let name = savedName, let bio = savedBio {
            vm.update(name: name, bio: bio)
            collectionView.reloadData()
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
                heightDimension: .absolute(360)
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
            if let name = container.viewWithTag(701) as? UILabel {
                name.text = viewModel?.name
            }
            if let redId = container.viewWithTag(702) as? UILabel {
                if let text = viewModel?.displayRedId {
                    redId.text = " \(text) "
                }
            }
            if let bio = container.viewWithTag(703) as? UILabel {
                bio.text = viewModel?.bio
            }
            if let avatar = container.viewWithTag(704) as? UIImageView, let vm = viewModel {
                avatar.image = loadSavedImage(forKey: ProfileStorageKeys.avatarPath) ?? UIImage(named: vm.avatarName) ?? UIImage(systemName: "person.circle.fill")
            }
            if let bg = container.viewWithTag(705) as? UIImageView, let vm = viewModel {
                bg.image = loadSavedImage(forKey: ProfileStorageKeys.backgroundPath) ?? UIImage(named: vm.bgName)
            }
            updateStats(existingStack)
            return
        }
        
        guard let vm = viewModel else { return }
        
        let bg = UIImageView()
        bg.tag = 705
        bg.image = loadSavedImage(forKey: ProfileStorageKeys.backgroundPath) ?? UIImage(named: vm.bgName)
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        container.addSubview(bg)

        let bgOverlay = UIView()
        bgOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        bg.addSubview(bgOverlay)
        
        let avatar = UIImageView()
        avatar.tag = 704
        avatar.image = loadSavedImage(forKey: ProfileStorageKeys.avatarPath) ?? UIImage(named: vm.avatarName) ?? UIImage(systemName: "person.circle.fill")
        avatar.layer.cornerRadius = 40
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = UIColor.white.cgColor
        avatar.clipsToBounds = true
        container.addSubview(avatar)
        
        let name = UILabel()
        name.tag = 701
        name.text = vm.name
        name.font = .systemFont(ofSize: 22, weight: .bold)
        container.addSubview(name)

        let redId = UILabel()
        redId.tag = 702
        redId.text = " \(vm.displayRedId) "
        redId.font = .systemFont(ofSize: 12, weight: .medium)
        redId.textColor = .secondaryLabel
        redId.backgroundColor = UIColor.systemGray6
        redId.layer.cornerRadius = 10
        redId.clipsToBounds = true
        redId.textAlignment = .center
        container.addSubview(redId)
        
        let bio = UILabel()
        bio.tag = 703
        bio.text = vm.bio
        bio.font = .systemFont(ofSize: 14)
        bio.textColor = .secondaryLabel
        bio.numberOfLines = 2
        container.addSubview(bio)
        
        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.spacing = 10
        container.addSubview(actionStack)
        
        let editButton = makeActionButton(title: "编辑资料", action: #selector(handleEditProfile))
        editButton.tag = 711
        let shareButton = makeActionButton(title: "分享", action: #selector(handleShareProfile))
        shareButton.tag = 712
        actionStack.addArrangedSubview(editButton)
        actionStack.addArrangedSubview(shareButton)
        
        let stack = UIStackView()
        stack.tag = 777
        stack.axis = .horizontal
        stack.spacing = 25
        stack.distribution = .equalSpacing
        container.addSubview(stack)
        
        // SnapKit 布局
        bg.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }
        bgOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        redId.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(6)
            make.height.equalTo(20)
        }
        bio.snp.makeConstraints { make in
            make.top.equalTo(redId.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        actionStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(avatar)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(bio.snp.bottom).offset(15)
            make.leading.equalTo(bio)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
            // Header 无需设置底部约束，它的高度由 Layout 中的 .absolute(360) 决定
        }
        
        updateStats(stack)
    }
    
    private func updateStats(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let vm = viewModel else { return }
        for stat in vm.stats {
            let count = (stat.title == "作品") ? "\(myPosts.count)" : stat.count
            let item = makeStatItem(count: count, title: stat.title)
            stack.addArrangedSubview(item)
        }
    }
    
    private func makeStatItem(count: String, title: String) -> UIView {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.alignment = .leading
        wrapper.spacing = 2
        
        let countLabel = UILabel()
        countLabel.text = count
        countLabel.font = .systemFont(ofSize: 16, weight: .bold)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        
        wrapper.addArrangedSubview(countLabel)
        wrapper.addArrangedSubview(titleLabel)
        return wrapper
    }
    
    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return button
    }
    
    private func makeActionButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = UIColor.systemBackground
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

// MARK: - Actions
extension ProfileViewController {
    @objc private func handleEditProfile() {
        guard let vm = viewModel else { return }
        let editVC = ProfileEditViewController(
            name: vm.name,
            bio: vm.bio,
            avatar: loadSavedImage(forKey: ProfileStorageKeys.avatarPath),
            background: loadSavedImage(forKey: ProfileStorageKeys.backgroundPath)
        )
        editVC.onSave = { [weak self] name, bio, avatar, background in
            guard let self = self else { return }
            vm.update(name: name, bio: bio)
            UserDefaults.standard.set(name, forKey: ProfileStorageKeys.name)
            UserDefaults.standard.set(bio, forKey: ProfileStorageKeys.bio)
            if let avatar = avatar {
                self.saveImage(avatar, forKey: ProfileStorageKeys.avatarPath, filename: "profile_avatar.png")
            }
            if let background = background {
                self.saveImage(background, forKey: ProfileStorageKeys.backgroundPath, filename: "profile_background.png")
            }
            self.collectionView.reloadData()
        }
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc private func handleShareProfile() {
        guard let vm = viewModel else { return }
        let shareText = "\(vm.name)\n\(vm.displayRedId)\n\(vm.bio)"
        var items: [Any] = [shareText]
        if let avatar = loadSavedImage(forKey: ProfileStorageKeys.avatarPath) ?? UIImage(named: vm.avatarName) {
            items.append(avatar)
        }
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(activity, animated: true)
    }
}

// MARK: - Local Image Storage
extension ProfileViewController {
    private func saveImage(_ image: UIImage, forKey key: String, filename: String) {
        guard let data = image.pngData() else { return }
        let url = profileImageURL(filename: filename)
        do {
            try data.write(to: url, options: .atomic)
            UserDefaults.standard.set(filename, forKey: key)
        } catch {
            return
        }
    }
    
    private func loadSavedImage(forKey key: String) -> UIImage? {
        guard let filename = UserDefaults.standard.string(forKey: key) else { return nil }
        let url = profileImageURL(filename: filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    private func profileImageURL(filename: String) -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(filename)
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
