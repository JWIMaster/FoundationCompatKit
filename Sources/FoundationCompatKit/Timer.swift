import Foundation
import UIKit

// iOS 10 Timer closure helper
class ClosureTimer: NSObject {
    let block: (Foundation.Timer) -> Void
    
    init(block: @escaping (Foundation.Timer) -> Void) {
        self.block = block
    }
    
    @objc func fire(_ timer: Foundation.Timer) {
        block(timer)
    }
}

public extension Foundation.Timer {
    
    /// iOS 10-style closure-based timer for older iOS
    @available(iOS, introduced: 6.0, obsoleted: 10.0)
    static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Foundation.Timer) -> Void) -> Foundation.Timer {
        let closureTimer = ClosureTimer(block: block)
        return Foundation.Timer.scheduledTimer(timeInterval: interval,
                                               target: closureTimer,
                                               selector: #selector(ClosureTimer.fire(_:)),
                                               userInfo: nil,
                                               repeats: repeats)
    }
}
