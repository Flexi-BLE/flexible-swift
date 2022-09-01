//
//  InfluxLineProtocol.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation

internal class ILPRecord {
    let measurement: String
    let timestamp: Date
    
    var tags: [String:String] = [:]
    var fields: [String:String] = [:]
    
    init(measurement: String, timestamp: Date) {
        self.measurement = measurement
        self.timestamp = timestamp
    }
    
    func tag(_ name: String, _ val: String) {
        tags[name] = "\"\(val)\""
    }
    
    func field(_ name: String, float: Float) {
        fields[name] = "\(float)"
    }
    
    func field(_ name: String, int: Int) {
        fields[name] = "\(int)i"
    }
    
    func field(_ name: String, uint: UInt) {
        fields[name] = "\(uint)u"
    }
    
    func field(_ name: String, str: String) {
        fields[name] = "\"\(str)\""
    }
    
    var line: String {
        var s = "\(measurement)"
        
        if !tags.isEmpty {
            for (name, tag) in tags {
                s += ",\(name)=\(tag)"
            }
        }
        
        if !fields.isEmpty {
            for (i, (name, value)) in fields.enumerated() {
                if i == 0 {
                    s += " "
                } else {
                    s += ","
                }
                
                s += "\(name)=\(value)"
            }
        }
        
        s += " \(timestamp.unixEpochNanoseconds)"
        
        return s
    }
}
