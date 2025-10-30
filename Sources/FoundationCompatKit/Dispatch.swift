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
    @available(iOS, introduced: 6.0, obsoleted: 8.0)
    class func global(qos: LegacyQoS.QoS) -> DispatchQueue {
        return DispatchQueue.global(priority: LegacyQoS(qos).legacyPriority)
    }
}

@available(iOS, introduced: 6.0, deprecated: 8.0)
public class DispatchWorkItem {
    private let block: () -> Void
    private(set) public var isCancelled: Bool = false
    private let lock = NSLock()

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }

    /// Run the work item if it hasn’t been cancelled
    public func perform() {
        lock.lock()
        let cancelled = isCancelled
        lock.unlock()
        guard !cancelled else { return }
        block()
    }

    /// Cancel the work item
    public func cancel() {
        lock.lock()
        isCancelled = true
        lock.unlock()
    }
}

public extension DispatchQueue {
    @available(iOS, introduced: 6.0, deprecated: 8.0)
    func async(execute workItem: DispatchWorkItem) {
        self.async {
            workItem.perform()
        }
    }

    @available(iOS, introduced: 6.0, deprecated: 8.0)
    func asyncAfter(deadline: DispatchTime, execute workItem: DispatchWorkItem) {
        let deltaNano = max(deadline.uptimeNanoseconds - DispatchTime.now().uptimeNanoseconds, 0)
        let deltaSeconds = Double(deltaNano) / 1_000_000_000
        self.asyncAfter(deadline: .now() + deltaSeconds) {
            workItem.perform()
        }
    }
}

public extension DispatchWorkItem {
    /// Notify simulation (runs on queue after execution)
    @available(iOS, introduced: 6.0, obsoleted: 8.0)
    func notify(queue: DispatchQueue = .main, block: @escaping () -> Void) {
        queue.async {
            guard !self.isCancelled else { return }
            block()
        }
    }
}

