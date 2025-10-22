//
//  File.swift
//  
//
//  Created by JWI on 22/10/2025.
//

import Foundation

@available(iOS, introduced: 6.0, deprecated: 8.0)
public struct LegacyQoS {
    public enum QoS {
        case userInteractive
        case userInitiated
        case `default`
        case utility
        case background
    }

    public let qos: QoS

    public init(_ qos: QoS) {
        self.qos = qos
    }

    fileprivate var legacyPriority: DispatchQueue.GlobalQueuePriority {
        switch qos { // <-- switch on the enum property, not self
        case .userInteractive, .userInitiated:
            return .high
        case .`default`:
            return .default
        case .utility:
            return .low
        case .background:
            return .background
        }
    }
}

public extension DispatchQueue {
    ///Modern style QoS wrapper for the old Swift overlay
    class func global(qos: LegacyQoS.QoS) -> DispatchQueue {
        return DispatchQueue.global(priority: LegacyQoS(qos).legacyPriority)
    }
}


public struct DispatchWorkItem {
    let block: () -> Void

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }

    public func perform() {
        block()
    }
}



public extension DispatchQueue {
    func async(execute workItem: DispatchWorkItem) {
        self.async {
            workItem.perform()
        }
    }

    func asyncAfter(deadline: DispatchTime, execute workItem: DispatchWorkItem) {
        let deltaNano = max(deadline.uptimeNanoseconds - DispatchTime.now().uptimeNanoseconds, 0)
        let deltaSeconds = Double(deltaNano) / 1_000_000_000
        self.asyncAfter(deadline: .now() + deltaSeconds) {
            workItem.perform()
        }
    }
}

extension DispatchWorkItem {
    func notify(qos: LegacyQoS.QoS = .default, queue: DispatchQueue = .main, block: @escaping () -> Void) {
        queue.asyncAfter(deadline: .now()) {
            block()
        }
    }
}

