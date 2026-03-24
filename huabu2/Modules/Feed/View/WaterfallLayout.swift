//
//  WaterfallLayout.swift
//  huabu
//
//  Created by zjs on 2026/3/6.
//

import UIKit

protocol WaterfallLayoutDelegate: AnyObject {
    // 告知布局：在当前列宽下，这个 Cell 总高度应该是多少（含图片和文字）
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, columnWidth: CGFloat) -> CGFloat
}

class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?
    
    private let numberOfColumns = 2      // 列数
    private let cellPadding: CGFloat = 6  // 间距
    
    // 缓存布局属性，避免重复计算
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        // 如果缓存不为空，说明已经算过了
        guard cache.isEmpty, let collectionView = collectionView else { return }
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            // 🔴 询问代理：这个 Cell 的总高度是多少？
            let itemHeight = delegate?.collectionView(collectionView, heightForItemAt: indexPath, columnWidth: columnWidth) ?? 200
            
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: itemHeight)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + itemHeight
            
            // 🔴 核心算法：寻找当前最短的那一列，把下一个 Cell 放过去
            column = yOffset[0] <= yOffset[1] ? 0 : 1
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        contentHeight = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return collectionView.bounds.size != newBounds.size
    }
}
