//
//  FXBTimeSeriesRecord.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

public protocol FXBTimeSeriesRecord: FetchableRecord & TableRecord {
    
    var ts: Int64 { get }
    var deviceName: String { get }
    var uploaded: Bool { get }
}

extension FXBTimeSeriesRecord {
    var tsDate: Date {
        return Date(timeIntervalSince1970: Double(self.ts) / 1_000_000.0)
    }
}
