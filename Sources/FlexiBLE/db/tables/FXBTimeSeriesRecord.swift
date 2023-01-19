//
//  FXBTimeSeriesRecord.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

public protocol FXBTimeSeriesRecord: FetchableRecord & TableRecord {
    
    var ts: Date { get }
    var deviceName: String { get }
    var uploaded: Bool { get }
    
}
