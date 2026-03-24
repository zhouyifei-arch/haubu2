import UIKit
import SnapKit
import PhotosUI // 核心：用于调用新的相册选择器

// EditorViewController 负责编辑页面的 UI 展示和交互逻辑
class EditorViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - 数据源
    // 定义贴纸图片名称数组（对应 Assets.xcassets 中的资源名）
    private let stickerList = ["sticker_01", "sticker_02", "sticker_03", "sticker_04", "sticker_05"]

    // MARK: - UI 组件
    private let mainCanvas = UIView() // 用户编辑的主区域
    
    // ⭐ 底板图片层：放在 mainCanvas 最底层
    private let canvasBackgroundView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill // 核心：让背景图铺满全屏
        iv.clipsToBounds = true // 裁剪超出部分
        iv.isUserInteractionEnabled = false // 核心：关闭交互，防止挡住贴纸的手势
        return iv
    }()
    
    private var stickers: [StickerContainerView] = [] // 数组：用来追踪和管理画布上生成的所有贴纸实例
    
    // 底部工具栏的黑色容器背景
    private let bottomToolBar = UIView()
    
    // 懒加载横向滑动列表，用于展示可供选择的贴纸预览图
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // 设置为横向滚动
        layout.itemSize = CGSize(width: 80, height: 80) // 每一个贴纸格子的尺寸
        layout.minimumInteritemSpacing = 15 // 格子之间的最小间距
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20) // 列表四周的内边距
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear // 背景透明，显示底部工具栏的黑色
        cv.showsHorizontalScrollIndicator = false // 隐藏底部的滚动条
        cv.delegate = self // 设置代理以处理点击事件
        cv.dataSource = self // 设置数据源以填充内容
        cv.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCell") // 注册自定义的格子类
        return cv
    }()

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI() // 初始化 UI 控件
        setupConstraints() // 设置 UI 控件的布局约束
    }

    // MARK: - UI 布局
    private func setupUI() {
        // 设置控制器背景色为紫色
        view.backgroundColor = UIColor(red: 0.45, green: 0.2, blue: 0.9, alpha: 1.0)
        title = "编辑器" // 设置导航栏标题
        
        // 1. 添加并配置主画布
        mainCanvas.backgroundColor = .white
        mainCanvas.clipsToBounds = true // 核心：防止贴纸超出画布区域显示
        view.addSubview(mainCanvas)
        
        // 2. 将背景层加到画布上（默认它是第一个，在最底层）
        mainCanvas.addSubview(canvasBackgroundView)
        
        // 3. 添加底部工具栏背景
        bottomToolBar.backgroundColor = UIColor(white: 0.0, alpha: 0.8) // 设置为 80% 透明度的黑色
        view.addSubview(bottomToolBar)
        
        // 4. 将贴纸选择列表添加到工具栏上
        bottomToolBar.addSubview(collectionView)
        
        // 创建一个点击手势：当用户点击白色画布的空白区域时
        let canvasTap = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap))
        canvasTap.delegate = self
        mainCanvas.addGestureRecognizer(canvasTap)
        
        // 5. 导航栏左侧：上传底板按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handlePhotoPicker))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        // 6. 导航栏右侧：保存按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(handleSave))
        navigationController?.navigationBar.tintColor = .white
        
        // 设置导航栏标题颜色为白色
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    private func setupConstraints() {
        mainCanvas.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(mainCanvas.snp.width)
        }
        
        canvasBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bottomToolBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(120)
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 逻辑处理
    
    @objc private func handleCanvasTap() {
        stickers.forEach { $0.isCurrentlySelected = false }
    }

    func selectSticker(_ target: StickerContainerView) {
        stickers.forEach { $0.isCurrentlySelected = ($0 == target) }
        if target.isCurrentlySelected {
            mainCanvas.bringSubviewToFront(target)
        }
    }
    
    // ⭐ 清除所有贴纸
    private func clearAllStickers() {
        stickers.forEach { $0.removeFromSuperview() }
        stickers.removeAll()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is StickerContainerView || touch.view?.superview is StickerContainerView {
            return false
        }
        return true
    }
}

// MARK: - 相册选择 (底板上传) 逻辑
extension EditorViewController: PHPickerViewControllerDelegate {
    
    @objc private func handlePhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let uiImage = image as? UIImage {
                    // ⭐ 上传新底图时清除所有贴纸
                    self?.clearAllStickers()
                    
                    self?.canvasBackgroundView.image = uiImage
                    self?.mainCanvas.backgroundColor = .clear
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}

// MARK: - 保存相册逻辑
extension EditorViewController {
    
    @objc private func handleSave() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.saveCanvasToAlbum()
                case .denied, .restricted:
                    self?.showAuthAlert()
                default:
                    break
                }
            }
        }
    }
    
    @objc private func saveCanvasToAlbum() {
        // 1. 先取消选中状态（清场）
        handleCanvasTap()
        
        // 2. 调用 ImageManager 执行保存逻辑
        ImageManager.shared.saveCanvasToAlbum(mainCanvas: self.mainCanvas) { [weak self] success, errorMessage in
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self?.showAlert(title: "保存成功", message: "图片已保存到系统相册")
            } else {
                self?.showAlert(title: "保存失败", message: errorMessage ?? "未知错误")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showAuthAlert() {
        showAlert(title: "无相册权限", message: "请在 iPhone 的“设置-隐私”中允许本应用访问相册。")
    }
}

// MARK: - CollectionView 代理
extension EditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCell
        cell.imageView.image = UIImage(named: stickerList[indexPath.item]) ?? UIImage(systemName: "face.smiling")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let name = stickerList[indexPath.item]
        let image = UIImage(named: name) ?? UIImage(systemName: "face.smiling")
        
        let stickerView = StickerContainerView(image: image)
        stickerView.bounds = CGRect(x: 0, y: 0, width: 120, height: 120)
        stickerView.center = CGPoint(x: mainCanvas.bounds.midX, y: mainCanvas.bounds.midY)
        
        mainCanvas.addSubview(stickerView)
        stickers.append(stickerView)
        selectSticker(stickerView)
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
