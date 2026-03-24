//
//  StickerCell.swift
//  huabu
//
//  Created by zjs on 2026/3/6.
//
import UIKit
import SnapKit
// MARK: - 自定义贴纸预览 Cell
class StickerCell: UICollectionViewCell {
    let imageView = UIImageView() // 预览图控件
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.1) // 背景设为微白透明
        contentView.layer.cornerRadius = 12 // 圆角效果
        
        imageView.contentMode = .scaleAspectFit // 图片比例缩放显示
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10) // 图片四周留出 10 的边距
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}
