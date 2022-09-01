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
    
    
    var unixEpochMilliseconds: TimeInterval {
        return (self.timeIntervalSince1970 * 1000.0).rounded()
    }
    
    var unixEpochNanoseconds: TimeInterval {
        return (self.timeIntervalSince1970 * 1000000000).rounded()
    }
}
