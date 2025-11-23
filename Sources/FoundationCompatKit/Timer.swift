
//
//  Timer.swift
//  Learning UIKit
//
//  Created by JWI on 28/08/2025.
//  Copyright (c) 2025 JWI. All rights reserved.
//

import Foundation
import UIKit


//iOS 10 Timer
class ClosureTimer: NSObject {
    let block: (Foundation.Timer) -> Void
    
    init(block: @escaping (Timer) -> Void) {
        self.block = block
    }
    
    @objc func fire(_ timer: Timer) {
        block(timer)
    }
}

extension Timer {
    
    ///iOS 10 Style Closure Based Timer
    @available(iOS, introduced: 6.0, obsoleted: 10.0)
    @_disfavoredOverload
    @objc public class func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let closureTimer = ClosureTimer(block: block)
        return Timer.scheduledTimer(timeInterval: interval,
                                                      target: closureTimer,
                                                      selector: #selector(ClosureTimer.fire(_:)),
                                                      userInfo: nil,
                                                      repeats: repeats)
    }
}







