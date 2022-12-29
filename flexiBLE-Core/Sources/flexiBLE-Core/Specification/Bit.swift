//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import Foundation

internal enum Bit {
    case zero
    case one
}

internal enum Endianness {
    case big
    case little
}

extension FixedWidthInteger {
    internal func bits(endianness: Endianness = .big) -> [Bit] {
        var bits = [Bit](repeating: .zero, count: Self.bitWidth)
    
        for i in 0..<Self.bitWidth {
            let bit = (self >> i) & 0x01
            bits[Self.bitWidth - 1 - i] = bit == 0 ? .zero : .one
        }
        
        switch endianness {
        case .big: return bits
            case .little: return bits.reversed()
        }
    }
    
    internal func bytes(endianness: Endianness = .big) -> [UInt8] {
        var bytes: [UInt8] = []
    
        for i in stride(from: (Self.bitWidth / 8) - 1, through: 0, by: -1) {
            var byte: UInt8 = 0
            if i == 0 {
                // must cast to in the case of signed values, maybe a bug?
                if Self.isSigned && self.bitWidth == 8 {
                    byte = UInt8(Int16(self) & 0xff)
                } else {
                    byte = UInt8(self & 0xff)
                }
            } else {
                byte = UInt8(self >> Int(i*8))
            }
            
            bytes.append(byte)
        }
        
        switch endianness {
        case .big: return bytes
        case .little: return bytes.map({ UInt8(littleEndian: $0) }).reversed()
        }
    }
}

