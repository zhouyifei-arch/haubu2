import UIKit
import SnapKit
import Kingfisher

class FeedCell: UICollectionViewCell {
    
    // MARK: - UI Components
    let coverImageView = UIImageView()
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let timeLabel = UILabel()
    
    // 删除按钮
    private let deleteButton: UIButton = {
        let btn = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .systemRed
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 11 // 圆角略小于按钮，确保不漏色
        btn.isHidden = true // 默认隐藏
        return btn
    }()
    
    // 删除回调闭包
    var deleteAction: (() -> Void)?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        // 卡片阴影 (作用在 cell 本身上，不是 contentView)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        
        contentView.addSubview(coverImageView)
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        contentView.addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        titleLabel.numberOfLines = 2
        
        contentView.addSubview(authorLabel)
        authorLabel.font = .systemFont(ofSize: 11)
        authorLabel.textColor = .gray
        
        contentView.addSubview(timeLabel)
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .lightGray
        timeLabel.textAlignment = .right
        
        // 添加删除按钮到最顶层
        contentView.addSubview(deleteButton)
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
        
        // SnapKit 布局
        coverImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(contentView.snp.width).multipliedBy(1.3)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(coverImageView.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(8)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.right.equalToSuperview().inset(8)
            make.left.greaterThanOrEqualTo(authorLabel.snp.right).offset(10)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(5)
            make.width.height.equalTo(22)
        }
        
        // 抗压缩优先级
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        authorLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    // MARK: - Logic
    @objc private func didTapDelete() {
        deleteAction?()
    }
    
    /// 进入/退出编辑模式（显示删除按钮 + 抖动效果）
    func showDeleteButton(_ show: Bool, canDelete: Bool = true) {
        let shouldShowDeleteButton = show && canDelete
        deleteButton.isHidden = !shouldShowDeleteButton
        
        if shouldShowDeleteButton {
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = -0.015
            animation.toValue = 0.015
            animation.duration = 0.1
            animation.repeatCount = .infinity
            animation.autoreverses = true
            contentView.layer.add(animation, forKey: "shaking")
        } else {
            contentView.layer.removeAnimation(forKey: "shaking")
        }
    }
    
    func configure(with post: FeedPost) {
        titleLabel.text = post.title
        authorLabel.text = post.source ?? "未知来源"
        timeLabel.text = post.ctime ?? "刚刚"
        
        guard var picStr = post.pic, !picStr.isEmpty else {
            coverImageView.image = UIImage(systemName: "photo")
            return
        }

        if picStr.hasPrefix("http") || picStr.hasPrefix("//") {
            // --- 情况 A：网络图片 ---
            if picStr.hasPrefix("//") { picStr = "https:" + picStr }
            if let url = URL(string: picStr) {
                coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
            }
        } else {
            // --- 情况 B：本地图片 ---
            // 1. 获取当前 App 运行时的 Documents 路径
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // 2. 核心兼容逻辑：
            // 如果数据库存的是全路径（带 UUID），我们只取最后的文件名
            // 如果存的就是文件名，lastPathComponent 依然是文件名
            let fileName = (picStr as NSString).lastPathComponent
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // 3. 加载图片
            if let localImage = UIImage(contentsOfFile: fileURL.path) {
                coverImageView.image = localImage
            } else {
                // 如果还是加载不到，显示占位图
                coverImageView.image = UIImage(systemName: "photo")
                print("⚠️ 无法在路径下找到图片: \(fileURL.path)")
            }
        }
    }
    
    // Cell 复用时重置状态
    override func prepareForReuse() {
        super.prepareForReuse()
        showDeleteButton(false)
        coverImageView.image = nil
        deleteAction = nil
    }
}
