//
//  TimeMachineLayout.swift
//  RunningMusic
//
//  Created by Cal on 10/11/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit

class TimeMachineLayout : UICollectionViewLayout {
    
    var currentDragPercentage: CGFloat = 0.0
    var transitioningToNewCurrent = true
    
    override class func layoutAttributesClass() -> AnyClass {
        return SongCell.self
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = SongCellAttributes(forCellWithIndexPath: indexPath)
        
        let item = Double(indexPath.item)
        let count = Double(collectionView!.numberOfItemsInSection(0))
        
        let width = collectionView!.frame.width - 2.0
        let aspect = CGFloat(101) / CGFloat(100)
        let height = aspect * width
        let size = CGSizeMake(width, height)
        
        let curved = pow((count - item) / count, 0.5)
        let scale = CGFloat(curved)
        attributes.transform = CGAffineTransformMakeScale(scale, scale)
        
        var offset = CGFloat(30 * item)
        if item != 0 && !transitioningToNewCurrent {
            offset -= (1.0 - currentDragPercentage) * 60.0
            offset = max(0, offset)
        }
        let bottom = collectionView!.frame.height - height
        let origin = CGPointMake(0, CGFloat(bottom - offset))
        
        attributes.frame = CGRect(origin: origin, size: size)
        attributes.zIndex = collectionView!.numberOfItemsInSection(0) - indexPath.item
        
        if item == 0 { attributes.textAlpha = 1.0 }
        else if item == 1 { attributes.textAlpha = 0.0 }
        else { attributes.textAlpha = 0.0 }
        
        return attributes
    }
    
    override func collectionViewContentSize() -> CGSize {
        return collectionView!.frame.size
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        
        for i in 0 ..< collectionView!.numberOfItemsInSection(0) {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            attributes.append(layoutAttributesForItemAtIndexPath(indexPath)!)
        }
        
        return attributes
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if itemIndexPath.item != collectionView!.numberOfItemsInSection(0) - 1 { return nil }
        let attributes = layoutAttributesForItemAtIndexPath(itemIndexPath)
        attributes?.zIndex = 0
        return attributes
    }
    
    override func finalLayoutAttributesForDisappearingDecorationElementOfKind(elementKind: String, atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: 9, inSection: 0))
        attributes?.transform = CGAffineTransformMakeScale(10.0, 10.0)
        return attributes
    }
}