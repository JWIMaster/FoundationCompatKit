//
//  File.swift
//  
//
//  Created by JWI on 22/10/2025.
//

import Foundation

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
        DispatchQueue.main.asyncAfter(deadline: .now() + deltaSeconds) {
            workItem.perform()
        }
    }
}
