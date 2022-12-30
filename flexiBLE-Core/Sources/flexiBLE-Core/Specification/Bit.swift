//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import Foundation

internal enum Bit: CustomStringConvertible {
    case zero
    case one
    
    var description: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        }
    }
}

typealias Byte = UInt8

extension Sequence where Element == Byte {
    func bits() -> [Bit] {
        return self.reduce([], { $0 + $1.bits() })
    }
}

extension Data {
    var bytes: [Byte] {
        return [Byte](self)
    }
    
    var bits: [Bit] {
        self.bytes.bits()
    }
}

extension Array where Element == Bit {
    func toFixWidthInt<T>(endianness: Endianness = .big) -> T where T:FixedWidthInteger {
        var sign: T = 1
        if T.isSigned && self[endianness == .big ? 0 : self.count-1] == .one {
            sign = -1
        }
        
        var fullBits = [Bit](repeating: sign == 1 ? .zero : .one, count: T.bitWidth)
        
        var copy = self
        if endianness == .little { copy = copy.reversed() }
        
        if self.count >= T.bitWidth {
            fullBits = Array(copy[0..<T.bitWidth])
        } else {
            fullBits.replaceSubrange(T.bitWidth - copy.count..<T.bitWidth, with: copy)
        }
        
        if T.isSigned {
            fullBits = Array(fullBits.dropFirst())
        }
        
        var result = fullBits
            .enumerated()
            .reduce(T(0)) { res, seq in
                if seq.element == .one {
                    
                    let exp: Int
                    switch endianness {
                    case .big:
                        exp = fullBits.count - 1 - seq.offset
                    case .little:
                        exp = seq.offset
                    }
                    
                    return res + T(pow(2.0, Float(exp)))
                }
                return res
            }
        
        if T.isSigned && result > 0 {
            result = T.min + result
        }
        
        return result
    }
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
    
    internal func bytes(endianness: Endianness = .big) -> [Byte] {
        var bytes: [Byte] = []
    
        for i in stride(from: (Self.bitWidth / 8) - 1, through: 0, by: -1) {
            var byte: Byte = 0
            if i == 0 {
                // must cast to in the case of signed values, maybe a bug?
                if Self.isSigned && self.bitWidth == 8 {
                    byte = Byte(Int16(self) & 0xff)
                } else {
                    byte = Byte(self & 0xff)
                }
            } else {
                byte = Byte(self >> Int(i*8))
            }
            
            bytes.append(byte)
        }
        
        switch endianness {
        case .big: return bytes
        case .little: return bytes.map({ Byte(littleEndian: $0) }).reversed()
        }
    }
}

extension BinaryFloatingPoint {
    internal func bits(endianness: Endianness = .big) -> [Bit] {
        let significandBits = UInt64(self.significandBitPattern).bits(endianness: endianness)[0..<Self.significandBitCount]
        let exponent = UInt16(self.exponentBitPattern).bits(endianness: endianness)[0..<Self.exponentBitCount]
        let sign = self.sign == .plus ? Bit.zero : .one
        
        let bitSize = Self.exponentBitCount + Self.significandBitCount + 1
        var bits = [Bit](repeating: .zero, count: bitSize)
        bits[0] = sign
        bits.replaceSubrange(1...Self.exponentBitCount, with: exponent)
        bits.replaceSubrange(1+Self.exponentBitCount..<bitSize, with: significandBits)
        return bits
    }
}

