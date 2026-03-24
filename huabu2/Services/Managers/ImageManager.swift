import UIKit
import Photos

class ImageManager: NSObject {
    
    static let shared = ImageManager()
    private override init() {}
    
    private var completionHandler: ((Bool, String?) -> Void)?

    
    func saveCanvasToAlbum(mainCanvas: UIView, completion: @escaping (Bool, String?) -> Void) {
        self.completionHandler = completion
        
        // 1. 检查权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    // 2. 生成截图 (调用下面的 captureImage)
                    if let image = self.captureImage(from: mainCanvas) {
                        // 3. 写入相册
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    } else {
                        completion(false, "截图生成失败")
                    }
                } else {
                    completion(false, "相册访问权限被拒绝")
                }
            }
        }
    }

    // 内部使用的截图逻辑
    private func captureImage(from view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completionHandler?(false, error.localizedDescription)
        } else {
            completionHandler?(true, nil)
        }
    }
}
