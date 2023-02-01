//
//  FXB+Date.swift
//  
//
//  Created by Blaine Rothrock on 8/8/22.
//

import Foundation

extension Date {
    func SQLiteFormat() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return formatter.string(from: self)
    }
    
    static func fromSQLString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        return formatter.date(from: str)
    }
    
    func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        return formatter.string(from: self)
    }
    
    
    var unixEpochMilliseconds: TimeInterval {
        return (self.timeIntervalSince1970 * 1_000.0).rounded()
    }
    
    var unixEpochMicroSeconds: Int64 {
        let micro = (self.timeIntervalSince1970 * 1_000_000.0).rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return Int64(truncating: numberFormatter.number(from: "\(micro)")!)
    }
    
    var unixEpochNanoseconds: Int64 {
        let nano = (self.timeIntervalSince1970 * 1_000_000_000.0).rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return Int64(truncating: numberFormatter.number(from: "\(nano)")!)
    }
    
    var dbPrimaryKey: Int64 {
        return Int64(self.unixEpochMicroSeconds)
    }
}
