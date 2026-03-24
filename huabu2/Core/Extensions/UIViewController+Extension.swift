import UIKit

extension UIViewController {
    
    static let swizzleViewWillAppear: Void = {
        let originalSelector = #selector(viewWillAppear(_:))
        let swizzledSelector = #selector(swizzled_viewWillAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc func swizzled_viewWillAppear(_ animated: Bool) {
        // 调用原始实现（此时 swizzled_viewWillAppear 指向原始实现）
        self.swizzled_viewWillAppear(animated)
        
        // 添加自定义逻辑
        print("📱 Current ViewController: \(String(describing: type(of: self)))")
    }
    
    // 提供一个静态方法来触发 Swizzling
    static func activateSwizzling() {
        _ = swizzleViewWillAppear
    }
}
