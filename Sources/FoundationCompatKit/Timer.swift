import Foundation
import UIKit

#if !os(macOS) && !targetEnvironment(macCatalyst)
@available(iOS, introduced: 6.0, obsoleted: 10.0)
public extension Foundation.Timer {

    /// Helper class for closure-based timer
    class ClosureTimer: NSObject {
        let block: (Foundation.Timer) -> Void

        init(block: @escaping (Foundation.Timer) -> Void) {
            self.block = block
        }

        @objc func fire(_ timer: Foundation.Timer) {
            block(timer)
        }
    }

    /// iOS 10-style closure-based scheduledTimer backport
    @available(iOS, introduced: 6.0, obsoleted: 10.0)
    static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Foundation.Timer) -> Void) -> Foundation.Timer {
        let closureTimer = ClosureTimer(block: block)
        return Foundation.Timer.scheduledTimer(
            timeInterval: interval,
            target: closureTimer,
            selector: #selector(ClosureTimer.fire(_:)),
            userInfo: nil,
            repeats: repeats
        )
    }
}
#endif
