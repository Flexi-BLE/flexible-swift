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
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        return formatter.string(from: self)
    }
    
    static func fromSQLString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
        
        return formatter.date(from: str)
    }
    
    
    var unixEpochMilliseconds: TimeInterval {
        return (self.timeIntervalSince1970 * 1000.0).rounded()
    }
    
    var unixEpochNanoseconds: Int {
        let nano = (self.timeIntervalSince1970 * 1000000000).rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return Int(numberFormatter.number(from: "\(nano)")!)
    }
}
