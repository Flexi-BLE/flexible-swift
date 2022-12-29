//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 12/28/22.
//

import Foundation

public extension Data {
    
    func insert(_ value: UInt8, at index: Data.Index?=nil) -> Data {
        if let index = index, index > self.count {
            return self.subdata(in: 0..<index) + Data([value]) + self.subdata(in: index..<self.count)
        } else {
            return self + Data([value])
        }
    }
    
//    func insert(_ value: UInt16, at index: Data.Index?=nil) -> Data {
//        if let index = index, index > self.count {
//            return self.subdata(in: 0..<index) + Data([value]) + self.subdata(in: index..<self.count)
//        } else {
//            return self + Data([value])
//        }
//    }
}
