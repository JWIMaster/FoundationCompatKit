//
//  File.swift
//  
//
//  Created by JWI on 23/11/2025.
//

import Foundation

public extension Data {
    @_disfavoredOverload
    init?(base64Encoded string: String) {
        let cleanedString = string
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        let base64Table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        var decodedBytes = [UInt8]()
        var buffer: UInt32 = 0
        var bufferLength = 0
        
        for char in cleanedString {
            if let index = base64Table.firstIndex(of: char) {
                let value = UInt32(base64Table.distance(from: base64Table.startIndex, to: index))
                buffer = (buffer << 6) | value
                bufferLength += 6
                if bufferLength >= 8 {
                    bufferLength -= 8
                    let byte = UInt8((buffer >> bufferLength) & 0xFF)
                    decodedBytes.append(byte)
                }
            } else if char == "=" {
                break
            } else {
                continue
            }
        }
        
        self.init(bytes: decodedBytes, count: decodedBytes.count)
    }
}
