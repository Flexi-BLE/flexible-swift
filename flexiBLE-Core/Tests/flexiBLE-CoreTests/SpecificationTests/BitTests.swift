//
//  BitTests.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import XCTest
@testable import flexiBLE_Core

final class BitTests: XCTestCase {
    
    func testBitToFixedUInt() throws {
        var byte = [Bit](repeating: .zero, count: 8)
    
        XCTAssert(byte.toFixWidthInt() == 0, "zero should be zero")
        
        byte = [Bit](repeating: .one, count: 16)
        XCTAssert(byte.toFixWidthInt() == UInt16.max, "should represent \(UInt16.max)")
        
        byte = UInt16(85).bits()
        XCTAssert(byte.toFixWidthInt() == UInt(85), "should represent 85")
        
        let twelveBits = [.one, .zero, .one, .one] + [Bit](repeating: .zero, count: 8)
        XCTAssert(twelveBits.toFixWidthInt() == UInt16(2816), "should represent 2816")
        XCTAssert(twelveBits.toFixWidthInt() == UInt32(2816), "should represent 2816")
        XCTAssert(twelveBits.toFixWidthInt() == UInt64(2816), "should represent 2816")
    }
    
    func testBitToFixedInt() throws {
        var value = 0
        var bits = Int(value).bits()
        XCTAssert(bits.toFixWidthInt() == value, "\(value) should be \(value)")
        
        value = -1
        bits = Int(value).bits()
        XCTAssert(bits.toFixWidthInt() == value, "\(value) should be \(value)")
        XCTAssert(bits.toFixWidthInt() == Int8(value), "\(value) should be \(value)")
        XCTAssert(bits.toFixWidthInt() == Int64(value), "\(value) should be \(value)")
        
        // when using signed integers -- a full byte value is expected. These results are not useful.
        bits = [.one, .zero, .one]
        XCTAssert(bits.toFixWidthInt() == Int8(-3), "zero should be zero")
        XCTAssert(bits.toFixWidthInt() == Int16(-3), "zero should be zero")
    }

    func testUInt8() throws {
        var  value: UInt8 = 0
        var bits = [Bit](repeating: .zero, count: 8)
        
        XCTAssert(value.bits() == bits, "zero should be zero")
        
        value = UInt8.max
        bits = [Bit](repeating: .one, count: 8)
        XCTAssert(value.bits() == bits, "\(UInt8.max) should be \(UInt8.max)")
        
        value = 114 // 01110010
        bits = [.zero, .one, .one, .one, .zero, .zero, .one, .zero]
        
        XCTAssert(value.bits() == bits, "114 should be 114")
        
        bits = bits.reversed()
        XCTAssert(value.bits(endianness: .little) == bits, "should respect little endian")
    }
    
    func testUInt16() throws {
        var value: UInt16 = 0
        var bits = [Bit](repeating: .zero, count: 16)
        var bytes: [UInt8] = [0, 0]
        
        XCTAssert(value.bits() == bits, "zero should be zero")
        XCTAssert(value.bytes() == bytes, "zero should be zero")
        
        value = UInt16.max
        bits = [Bit](repeating: .one, count: 16)
        bytes = [255, 255]
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
        
        value = (UInt16.max / 2) - 1
        bits = [.zero] + [Bit](repeating: .one, count: 14) + [.zero]
        bytes = [127, 254]
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
        
        value = (UInt16.max / 2)
        bits = [Bit](repeating: .one, count: 15) + [.zero]
        bytes = [255, 127]
        
        XCTAssert(value.bits(endianness: .little) == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes(endianness: .little) == bytes, "\(value) should be \(value)")
    }
    
    func testInt8() throws {
        var value: Int8 = 0
        var bits = [Bit](repeating: .zero, count: 8)
        var bytes: [UInt8] = [0]
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
        
        value = -1
        bits = [Bit](repeating: .one, count: 8)
        bytes = [255]
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
        
        value = -128
        bits = [.one] + [Bit](repeating: .zero, count: 7)
        bytes = [128]
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
    }
    
    func testInttoBytestoBit() throws {
        let value = UInt16.max
        let bytes = value.bytes()
        let bits = value.bits()
        XCTAssert(bytes.bits() == bits)
        
    }
    
    func testExtraction() throws {
        let bits: [Bit] = [Bit](repeating: .zero, count: 100) + [.one, .zero, .one, .zero, .one] + [Bit](repeating: .zero, count: 100)
        XCTAssert(Array(bits[100...104]).toFixWidthInt() == UInt(21))
    }
    
    func testFloat() throws {
        var value: Float = 0
        var bits = [Bit](repeating: .zero, count: 32)
        var bytes = [UInt8](repeating: 0, count: 8)
    
        
        XCTAssert(value.bits() == bits, "\(value) should be \(value)")
//        XCTAssert(value.bytes() == bytes, "\(value) should be \(value)")
    }
}
