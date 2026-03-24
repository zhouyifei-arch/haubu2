import UIKit
import SnapKit
import RealmSwift

class CreatePostViewController: UIViewController {

    // MARK: - UI Components
    // 1. 标题输入框 (单行)
    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "填写标题"
        tf.font = .systemFont(ofSize: 18, weight: .bold)
        tf.borderStyle = .none
        return tf
    }()
    
    // 分割线
    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        return view
    }()

    // 2. 详情描述框 (多行)
    private let descTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.isScrollEnabled = true
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "添加正文描述..."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        return label
    }()
    
    // 3. 图片展示
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        iv.layer.cornerRadius = 8
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        
        let icon = UIImageView(image: UIImage(systemName: "camera.fill"))
        icon.tintColor = .lightGray
        icon.tag = 99
        iv.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        return iv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupUI()
        
        descTextView.delegate = self
        
        // 点击空白处收起键盘
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        // 图片点击手势
        let photoTap = UITapGestureRecognizer(target: self, action: #selector(selectPhoto))
        photoImageView.addGestureRecognizer(photoTap)
    }
    
    private func setupNav() {
        view.backgroundColor = .white
        title = "发动态"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(dismissSelf))
        
        let postBtn = UIButton(type: .system)
        postBtn.setTitle("发布", for: .normal)
        postBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        postBtn.setTitleColor(.white, for: .normal)
        postBtn.backgroundColor = .systemRed // 改为红色更有活力
        postBtn.layer.cornerRadius = 16
        postBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        postBtn.addTarget(self, action: #selector(handlePost), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: postBtn)
    }
    
    private func setupUI() {
        view.addSubview(titleField)
        view.addSubview(lineView)
        view.addSubview(descTextView)
        descTextView.addSubview(placeholderLabel)
        view.addSubview(photoImageView)
        
        titleField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        lineView.snp.makeConstraints { make in
            make.top.equalTo(titleField.snp.bottom).offset(5)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(0.5)
        }
        
        descTextView.snp.makeConstraints { make in
            make.top.equalTo(lineView.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16) // TextView 内边距稍小
            make.height.equalTo(150)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(5)
        }
        
        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(descTextView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.width.height.equalTo(100)
        }
    }

    // MARK: - Actions
    @objc private func selectPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    // MARK: - Actions
    @objc private func handlePost() {
        // 0. 基础校验
        guard let titleStr = titleField.text, !titleStr.isEmpty else {
            print("⚠️ 标题不能为空")
            // 这里可以加一个简单的弹窗提醒用户
            return
        }
        
        // 1. 创建模型并赋值
        let newPost = FeedPost()
        newPost.id = UUID().uuidString
        newPost.title = titleStr
        newPost.desc = descTextView.text
        newPost.source = "iPhone" // 你也可以改为用户真实的设备名
        newPost.isLocal = true
        // --- 🔴 关键修改：获取并格式化当前真实日期时间 ---
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        newPost.ctime = formatter.string(from: Date())
        // -------------------------------------------
        
        // 2. 处理图片路径
        // 逻辑：如果图片框有图，且占位视图（tag 99）已隐藏，说明用户选了图
        if let image = photoImageView.image, photoImageView.viewWithTag(99)?.isHidden == true {
            if let fileName = saveImageToDoc(image: image) {
                newPost.pic = fileName // 存储沙盒中的文件名
            }
        }

        // 3. 写入 Realm 数据库
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newPost)
                print("✅ 成功发布动态！时间为：\(newPost.ctime ?? "")")
            }
            
            // 4. 发送全局通知，告知 FeedViewController 刷新数据
            NotificationCenter.default.post(name: NSNotification.Name("DidPostNewContent"), object: nil)
            
            // 5. 退出发布页面
            dismiss(animated: true)
            
        } catch {
            print("❌ Realm 写入失败: \(error)")
            // 这里可以给用户一个“发布失败”的提示
        }
    }

    // MARK: - Helper Methods
    /// 将图片保存到沙盒 Document 目录，并仅返回文件名以应对沙盒路径变更问题
    private func saveImageToDoc(image: UIImage) -> String? {
        // 将图片压缩为 Data
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        // 生成唯一文件名
        let fileName = "\(UUID().uuidString).jpg"
        
        // 获取 Document 目录的 URL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("🖼 图片已保存至本地: \(fileName)")
            return fileName // 🟢 关键：只返回文件名，不要返回全路径
        } catch {
            print("❌ 图片写入沙盒失败: \(error)")
            return nil
        }
    }
}

// MARK: - Delegate Extensions
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension CreatePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            photoImageView.image = image
            photoImageView.viewWithTag(99)?.isHidden = true
        }
        picker.dismiss(animated: true)
    }
}
