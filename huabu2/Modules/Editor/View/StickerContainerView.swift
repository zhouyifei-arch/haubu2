//  StickerContainerView.swift
//  huabu
//
//  Created by zjs on 2026/3/5.
//

import UIKit
import SnapKit

// MARK: - 贴纸容器：核心类，处理贴纸的展示、虚线框、手势、删除和旋转缩放
class StickerContainerView: UIView {
    // 基础 UI 组件变量
    private let contentView = UIImageView()  // 真正显示像素画内容的图片视图
    private let borderLayer = CAShapeLayer() // 负责绘制选中时的虚线边框层
    private let deleteButton = UIButton()    // 位于左上角的删除操作按钮
    private let scaleButton = UIButton()     // 位于右下角的缩放与旋转操作手柄
    
    // 交互状态记录变量（用于手势增量计算）
    private var initialDistance: CGFloat = 1.0              // 手势开始时手指距离贴纸中心的物理距离
    private var initialTransform: CGAffineTransform = .identity // 手势开始时贴纸的原始变换状态（缩放/角度）
    private var initialAngle: CGFloat = 0.0                 // 手势开始时手指相对于中心点的初始弧度角

    // 关键业务属性：控制贴纸是否处于“激活/选中”状态
    var isCurrentlySelected: Bool = false {
        didSet {
            // 当选中状态发生变化时，自动显示或隐藏辅助工具（边框、删除按钮、缩放按钮）
            borderLayer.isHidden = !isCurrentlySelected
            deleteButton.isHidden = !isCurrentlySelected
            scaleButton.isHidden = !isCurrentlySelected
        }
    }

    // 初始化方法
    init(image: UIImage?) {
        super.init(frame: .zero)
        self.backgroundColor = .clear // 容器设为透明，保证只看到贴纸和边框
        
        // 1. 初始化贴纸内容视图
        contentView.image = image
        contentView.contentMode = .scaleAspectFit // 确保贴纸内容比例正确
        addSubview(contentView)
        
        // 2. 初始化并配置虚线边框层（CAShapeLayer）
        borderLayer.strokeColor = UIColor.black.cgColor // 边框颜色
        borderLayer.fillColor = nil                     // 内部不填充颜色
        borderLayer.lineWidth = 1.5                    // 线宽
        borderLayer.lineDashPattern = [4, 4]           // 虚线模式：4点实线，4点空白
        layer.addSublayer(borderLayer)
        
        // 3. 配置删除按钮
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed            // 设置为醒目的红色
        deleteButton.backgroundColor = .white          // 白色背景增加清晰度
        deleteButton.layer.cornerRadius = 12           // 圆角处理
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside) // 绑定删除逻辑
        addSubview(deleteButton)
        
        // 4. 配置缩放旋转手柄按钮
        scaleButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right.circle.fill"), for: .normal)
        scaleButton.tintColor = .systemBlue            // 设置为醒目的蓝色
        scaleButton.backgroundColor = .white           // 白色背景增加清晰度
        scaleButton.layer.cornerRadius = 12            // 圆角处理
        // 重要：为缩放按钮单独添加拖动手势（Pan手势）来实现旋转缩放
        scaleButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleScaleRotatePan(_:))))
        addSubview(scaleButton)
        
        // 5. 为整个容器添加拖动手势，实现贴纸的平移位置功能
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleMovePan(_:))))
        
        // 6. 调用约束设置方法
        setupConstraints()
    }

    // 设置子视图布局约束（使用 SnapKit）
    private func setupConstraints() {
        // 让图片视图在容器内四周留出 12 像素空隙，用来放置溢出的功能按钮
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        // 删除按钮：中心点对齐图片视图的左上角
        deleteButton.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.left)
            make.centerY.equalTo(contentView.snp.top)
            make.width.height.equalTo(24) // 按钮大小 24x24
        }
        // 缩放按钮：中心点对齐图片视图的右下角
        scaleButton.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.right)
            make.centerY.equalTo(contentView.snp.bottom)
            make.width.height.equalTo(24) // 按钮大小 24x24
        }
    }

    // 系统布局更新回调：当 View 尺寸变化时刷新虚线框路径
    override func layoutSubviews() {
        super.layoutSubviews()
        // 将虚线框的矩形路径同步为当前图片视图的 frame 大小
        borderLayer.path = UIBezierPath(rect: contentView.frame).cgPath
    }

    // 触摸开始事件：实现组件间的“选中通知”
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // 通过响应者链（next）找到上层控制器，并通知它选中当前贴纸，将其置顶
        if let vc = self.next(of: EditorViewController.self) {
            vc.selectSticker(self)
        }
    }

    // 处理贴纸位置移动的 Pan 手势逻辑
    @objc private func handleMovePan(_ gesture: UIPanGestureRecognizer) {
        guard isCurrentlySelected else { return }
        let translation = gesture.translation(in: superview)
        
        // 1. 计算出“如果按照手指移动，贴纸的新中心点在哪里”
        var newCenter = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        
        // 2. 获取父容器（画布）的尺寸限制
        // 这里的 superview 就是 EditorViewController 里的 mainCanvas
        guard let canvas = superview else { return }
        
        // 3. 核心限制逻辑：防止中心点溢出边界
        // 限制 X 轴：不能小于 0，不能大于画布宽度
        newCenter.x = max(0, min(newCenter.x, canvas.bounds.width))
        
        // 限制 Y 轴：不能小于 0，不能大于画布高度
        newCenter.y = max(0, min(newCenter.y, canvas.bounds.height))
        
        // 4. 将经过修正的坐标赋值给贴纸
        self.center = newCenter
        
        // 重置位移增量
        gesture.setTranslation(.zero, in: superview)
    }

    // 核心数学算法：处理缩放与旋转复合变换
    @objc private func handleScaleRotatePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let location = gesture.location(in: superview) // 当前手指在画布中的位置坐标
        let center = self.center // 贴纸的中心坐标点
        
        if gesture.state == .began {
            // 手势刚开始：利用勾股定理计算手指到中心的初始距离
            initialDistance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
            // 利用 atan2 函数计算手指相对于中心点的初始弧度角
            initialAngle = atan2(location.y - center.y, location.x - center.x)
            // 保存当前的 Transform 状态，用于在此基础上进行变换累加
            initialTransform = self.transform
        } else if gesture.state == .changed {
            // 手势移动中：计算手指当前到中心点的距离
            let currentDistance = sqrt(pow(location.x - center.x, 2) + pow(location.y - center.y, 2))
            // 计算手指当前相对于中心点的弧度角
            let currentAngle = atan2(location.y - center.y, location.x - center.x)
            
            // 计算缩放比例 = 当前距离 / 初始距离（设置最小缩放阈值为 0.3 倍）
            let scale = max(currentDistance / initialDistance, 0.3)
            // 计算旋转增量角度 = 当前角度 - 初始角度
            let angleDelta = currentAngle - initialAngle
            
            // 重要：将缩放 (Scale) 和旋转 (Rotate) 效果通过 Transform 合并应用到视图上
            self.transform = initialTransform.scaledBy(x: scale, y: scale).rotated(by: angleDelta)
        }
    }

    // 删除按钮点击事件：将贴纸从父视图（画布）中移除销毁
    @objc private func handleDelete() {
        self.removeFromSuperview()
    }
    
    // 必要的初始化检查
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - 响应者链扩展：实现低耦合的组件通信 (符合第46天路由设计思想)
extension UIResponder {
    // 递归查找响应者链，直到找到指定类型的对象（如 ViewController）
    func next<T: UIResponder>(of type: T.Type) -> T? {
        return next as? T ?? next?.next(of: type)
    }
}
