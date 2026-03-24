import UIKit
import SnapKit
import Kingfisher

class FeedDetailViewController: UIViewController {
    
    private let post: FeedPost
    
    // MARK: - UI 组件
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 1. 作者/来源
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    // 2. 主图
    private let mainImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        return iv
    }()
    
    // 3. 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    // 4. 正文内容
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // 5. 评论区容器
    private let commentSectionView = UIView()
    private let commentTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "评论 (0)"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let emptyCommentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()

    // MARK: - 初始化
    init(post: FeedPost) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "详情"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        // --- 顺序布局 ---
        
        // 1. 作者
        contentView.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // 2. 图片
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(16)
            // 设为 16:9 比例或 4:3 比例，更符合图片展示
            make.height.equalTo(mainImageView.snp.width).multipliedBy(0.75)
        }
        
        // 3. 标题
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // 4. 正文
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // 分割线
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        // 5. 评论区
        contentView.addSubview(commentSectionView)
        commentSectionView.snp.makeConstraints { make in
            make.top.equalTo(line.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40) // 🔴 底部留白，决定 contentSize
            make.height.equalTo(200)
        }
        
        commentSectionView.addSubview(commentTitleLabel)
        commentTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(16)
        }
        
        setupEmptyState()
    }
    
    private func setupEmptyState() {
        let iconLabel = UILabel()
        iconLabel.text = "💬"
        iconLabel.font = .systemFont(ofSize: 40)
        
        let tipLabel = UILabel()
        tipLabel.text = "还没有人评论，快来抢沙发吧"
        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.textColor = .lightGray
        
        emptyCommentStack.addArrangedSubview(iconLabel)
        emptyCommentStack.addArrangedSubview(tipLabel)
        
        commentSectionView.addSubview(emptyCommentStack)
        emptyCommentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func displayData() {
        authorLabel.text = (post.source != nil && !post.source!.isEmpty) ? post.source : "精选画布"
        titleLabel.text = post.title
        
        // 处理正文 (设置行间距)
        let contentText = (post.desc != nil && !post.desc!.isEmpty) ? post.desc! : "暂无内容简介..."
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attrString = NSAttributedString(string: contentText,
                                            attributes: [.paragraphStyle: paragraphStyle,
                                                         .font: UIFont.systemFont(ofSize: 17),
                                                         .foregroundColor: UIColor.darkGray])
        contentLabel.attributedText = attrString
        
        // 🔴 核心修改：图片加载逻辑（兼容本地与网络）
        guard var picStr = post.pic, !picStr.isEmpty else {
            mainImageView.image = UIImage(systemName: "photo")
            return
        }
        
        if picStr.hasPrefix("http") || picStr.hasPrefix("//") {
            // 情况 A: 网络图片
            if picStr.hasPrefix("//") { picStr = "https:" + picStr }
            if let url = URL(string: picStr) {
                mainImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
            }
        } else {
            // 情况 B: 本地图片（仅存储文件名）
            // 动态拼接当前的 Documents 路径，解决重启后 UUID 变动问题
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(picStr)
            
            if let localImage = UIImage(contentsOfFile: fileURL.path) {
                mainImageView.image = localImage
            } else {
                // 如果存的是旧的全路径（带 UUID 的），尝试只取最后的文件名部分进行兜底
                let fileName = (picStr as NSString).lastPathComponent
                let fallbackURL = documentsPath.appendingPathComponent(fileName)
                mainImageView.image = UIImage(contentsOfFile: fallbackURL.path) ?? UIImage(systemName: "photo")
            }
        }
    }
}
