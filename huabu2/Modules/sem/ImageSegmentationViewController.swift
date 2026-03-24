import UIKit
import SnapKit
import BackgroundRemoval
import Photos

class ImageSegmentationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI
    private let mainCanvas = UIImageView()
    private let checkerboardView = UIView()
    private let previewControl = UISegmentedControl(items: ["结果", "原图"])
    private let selectButton = UIButton(type: .system)
    private let saveTransparentButton = UIButton(type: .system)
    private let saveWhiteBackgroundButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let hintLabel = UILabel()

    // MARK: - Data
    private var originalImage: UIImage?
    private var processedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupGesture()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        title = "抠图"

        checkerboardView.layer.cornerRadius = 16
        checkerboardView.clipsToBounds = true
        checkerboardView.backgroundColor = generateCheckerboardColor()
        view.addSubview(checkerboardView)

        mainCanvas.contentMode = .scaleAspectFit
        mainCanvas.isUserInteractionEnabled = true
        checkerboardView.addSubview(mainCanvas)

        hintLabel.text = "处理完成后，长按可瞬时对比原图"
        hintLabel.textColor = .lightGray
        hintLabel.font = .systemFont(ofSize: 14)
        hintLabel.isHidden = true
        view.addSubview(hintLabel)

        previewControl.selectedSegmentIndex = 0
        previewControl.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        previewControl.selectedSegmentTintColor = .white
        previewControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        previewControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        previewControl.isEnabled = false
        previewControl.addTarget(self, action: #selector(handlePreviewChanged), for: .valueChanged)
        view.addSubview(previewControl)

        configurePrimaryButton(selectButton, title: "选择图片", backgroundColor: .systemPurple, titleColor: .white)
        selectButton.addTarget(self, action: #selector(handlePickImage), for: .touchUpInside)
        view.addSubview(selectButton)

        configurePrimaryButton(saveTransparentButton, title: "保存透明结果", backgroundColor: .white, titleColor: .black)
        saveTransparentButton.addTarget(self, action: #selector(handleSaveTransparentImage), for: .touchUpInside)
        view.addSubview(saveTransparentButton)

        configurePrimaryButton(
            saveWhiteBackgroundButton,
            title: "保存白底图",
            backgroundColor: UIColor.white.withAlphaComponent(0.12),
            titleColor: .white
        )
        saveWhiteBackgroundButton.addTarget(self, action: #selector(handleSaveWhiteBackgroundImage), for: .touchUpInside)
        view.addSubview(saveWhiteBackgroundButton)

        loadingIndicator.color = .white
        view.addSubview(loadingIndicator)

        updateActionState(hasProcessedImage: false)
    }

    private func configurePrimaryButton(_ button: UIButton, title: String, backgroundColor: UIColor, titleColor: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, for: .normal)
        button.layer.cornerRadius = 22
    }

    private func setupConstraints() {
        checkerboardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalTo(previewControl.snp.top).offset(-18)
        }

        mainCanvas.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(checkerboardView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }

        previewControl.snp.makeConstraints { make in
            make.bottom.equalTo(saveTransparentButton.snp.top).offset(-16)
            make.leading.trailing.equalToSuperview().inset(32)
            make.height.equalTo(36)
        }

        saveTransparentButton.snp.makeConstraints { make in
            make.bottom.equalTo(saveWhiteBackgroundButton.snp.top).offset(-12)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(44)
        }

        saveWhiteBackgroundButton.snp.makeConstraints { make in
            make.bottom.equalTo(selectButton.snp.top).offset(-15)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(44)
        }

        selectButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(50)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(checkerboardView)
        }
    }

    // MARK: - Processing
    private func processImage(_ image: UIImage) {
        loadingIndicator.startAnimating()
        updateActionState(hasProcessedImage: false)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let remover = BackgroundRemoval()
                let rawResult = try remover.removeBackground(image: image)

                var finalImage = self.fixTransparency(for: rawResult)
                if let data = finalImage?.pngData() {
                    finalImage = UIImage(data: data)
                }

                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.processedImage = finalImage
                    self.previewControl.selectedSegmentIndex = 0
                    self.updateActionState(hasProcessedImage: finalImage != nil)

                    UIView.transition(with: self.mainCanvas, duration: 0.4, options: .transitionCrossDissolve) {
                        self.mainCanvas.image = finalImage
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.processedImage = nil
                    self.previewControl.selectedSegmentIndex = 1
                    self.updateActionState(hasProcessedImage: false)
                    self.mainCanvas.image = self.originalImage
                    self.presentAlert(title: "处理失败", message: "这张图片暂时无法完成抠图，请换一张图再试。")
                }
            }
        }
    }

    private func fixTransparency(for image: UIImage) -> UIImage? {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func imageByAddingWhiteBackground(to image: UIImage) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func updateActionState(hasProcessedImage: Bool) {
        previewControl.isEnabled = hasProcessedImage && originalImage != nil
        saveTransparentButton.isEnabled = hasProcessedImage
        saveTransparentButton.alpha = hasProcessedImage ? 1.0 : 0.5
        saveWhiteBackgroundButton.isEnabled = hasProcessedImage
        saveWhiteBackgroundButton.alpha = hasProcessedImage ? 1.0 : 0.5
        hintLabel.isHidden = !hasProcessedImage
    }

    private func generateCheckerboardColor() -> UIColor {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()

        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context?.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        context?.fill(CGRect(x: 10, y: 10, width: 10, height: 10))

        UIColor.white.withAlphaComponent(0.3).setFill()
        context?.fill(CGRect(x: 10, y: 0, width: 10, height: 10))
        context?.fill(CGRect(x: 0, y: 10, width: 10, height: 10))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: image ?? UIImage())
    }

    // MARK: - Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let original = originalImage, let processed = processedImage else { return }
        mainCanvas.image = gesture.state == .began ? original : processed
    }

    @objc private func handlePreviewChanged() {
        guard let original = originalImage, let processed = processedImage else { return }
        mainCanvas.image = previewControl.selectedSegmentIndex == 0 ? processed : original
    }

    @objc private func handlePickImage() {
        let sheet = UIAlertController(title: "选择图片", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "拍照", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .camera)
        })
        sheet.addAction(UIAlertAction(title: "从相册选择", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = selectButton
            popover.sourceRect = selectButton.bounds
        }

        present(sheet, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            let message = sourceType == .camera ? "当前设备不支持拍照。" : "当前设备无法访问相册。"
            presentAlert(title: "不可用", message: message)
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            originalImage = image
            processedImage = nil
            previewControl.selectedSegmentIndex = 1
            mainCanvas.image = image
            updateActionState(hasProcessedImage: false)
            processImage(image)
        }
        picker.dismiss(animated: true)
    }

    @objc private func handleSaveTransparentImage() {
        guard let image = processedImage else { return }
        saveImageToPhotoLibrary(image)
    }

    @objc private func handleSaveWhiteBackgroundImage() {
        guard let image = processedImage, let whiteBackgroundImage = imageByAddingWhiteBackground(to: image) else { return }
        saveImageToPhotoLibrary(whiteBackgroundImage)
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.imageSaveFinished), nil)
                } else {
                    self.presentAlert(title: "无法保存", message: "请在系统设置里允许访问相册。")
                }
            }
        }
    }

    @objc private func imageSaveFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let title = error == nil ? "成功" : "失败"
        let message = error == nil ? "图片已存入相册" : (error?.localizedDescription ?? "保存失败")
        presentAlert(title: title, message: message)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Gesture
    private func setupGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0
        mainCanvas.addGestureRecognizer(longPress)
    }
}
