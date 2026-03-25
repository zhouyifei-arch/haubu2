import UIKit
import SnapKit

final class ProfileEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private enum ImageTarget {
        case avatar
        case background
    }

    private let initialName: String
    private let initialBio: String
    private let initialAvatar: UIImage?
    private let initialBackground: UIImage?

    var onSave: ((String, String, UIImage?, UIImage?) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundImageView = UIImageView()
    private let avatarImageView = UIImageView()
    private let nameField = UITextField()
    private let bioField = UITextField()
    private let saveButton = UIButton(type: .system)

    private var currentImageTarget: ImageTarget?

    init(name: String, bio: String, avatar: UIImage?, background: UIImage?) {
        self.initialName = name
        self.initialBio = bio
        self.initialAvatar = avatar
        self.initialBackground = background
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "编辑资料"
        view.backgroundColor = .systemBackground
        setupUI()
        applyInitialValues()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = UIColor.systemGray5
        contentView.addSubview(backgroundImageView)

        let changeBackgroundButton = makeActionButton(title: "更换背景", action: #selector(handleChangeBackground))
        contentView.addSubview(changeBackgroundButton)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.backgroundColor = UIColor.systemGray5
        contentView.addSubview(avatarImageView)

        let changeAvatarButton = makeActionButton(title: "更换头像", action: #selector(handleChangeAvatar))
        contentView.addSubview(changeAvatarButton)

        nameField.borderStyle = .roundedRect
        nameField.placeholder = "昵称"
        nameField.clearButtonMode = .whileEditing
        contentView.addSubview(nameField)

        bioField.borderStyle = .roundedRect
        bioField.placeholder = "简介"
        bioField.clearButtonMode = .whileEditing
        contentView.addSubview(bioField)

        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        contentView.addSubview(saveButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }
        changeBackgroundButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(backgroundImageView.snp.bottom).offset(-12)
        }
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(backgroundImageView.snp.bottom).offset(-40)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }
        changeAvatarButton.snp.makeConstraints { make in
            make.centerY.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
        }
        nameField.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        bioField.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(12)
            make.leading.trailing.equalTo(nameField)
            make.height.equalTo(40)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(bioField.snp.bottom).offset(24)
            make.leading.trailing.equalTo(nameField)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-30)
        }
    }

    private func applyInitialValues() {
        nameField.text = initialName
        bioField.text = initialBio
        avatarImageView.image = initialAvatar
        backgroundImageView.image = initialBackground
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

    @objc private func handleChangeAvatar() {
        currentImageTarget = .avatar
        presentImagePicker()
    }

    @objc private func handleChangeBackground() {
        currentImageTarget = .background
        presentImagePicker()
    }

    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func handleSave() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bio = bioField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let finalName = name.isEmpty ? initialName : name
        let finalBio = bio
        onSave?(finalName, finalBio, avatarImageView.image, backgroundImageView.image)
        navigationController?.popViewController(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        switch currentImageTarget {
        case .avatar:
            avatarImageView.image = image
        case .background:
            backgroundImageView.image = image
        case .none:
            break
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
