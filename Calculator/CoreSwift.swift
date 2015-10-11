//
//  CoreSwift.swift
//  RunningMusic
//
//  Created by Cal on 10/10/15.
//  Copyright © 2015 Cal. All rights reserved.
//

import Foundation
import UIKit

///short-form function to run a block synchronously on the main queue
func sync(closure: () -> ()) {
    dispatch_sync(dispatch_get_main_queue(), closure)
}

///short-form function to run a block asynchronously on the main queue
func async(closure: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), closure)
}

///perform the closure function after a given delay
func delay(delay: Double, closure: ()->()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), closure)
}

extension Array {
    ///Returns a copy of the array in random order
    func shuffled() -> [Element] {
        var list = self
        if self.count == 0 { return self }
        for i in 0..<(list.count - 1) {
            
            var j = i
            while j == i {
                j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            }
            
            swap(&list[i], &list[j])
        }
        return list
    }
}

extension CGPoint {
    
    func distanceTo(other: CGPoint) -> CGFloat {
        return CGFloat(sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2)))
    }
    
}
