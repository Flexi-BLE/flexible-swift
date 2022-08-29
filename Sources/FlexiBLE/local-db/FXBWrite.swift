//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 8/6/22.
//

import Foundation

public struct FXBWrite {
    
    let dbMgr = FXBDBManager.shared
    
    // MARK: - Connection
    public func recordConnection(deviceName: String, status: FXBConnection.Status) async throws {
        try await dbMgr.dbQueue.write({ db in
            var connection = FXBConnection(device: deviceName, status: status)
            try connection.insert(db)
        })
    }
    
    // MARK: - Throughput
    public func recordThroughput(deviceName: String, dataStreamName: String, byteCount: Int) async throws {

        try await dbMgr.dbQueue.write { db in
            var throughput = FXBThroughput(
                device: deviceName,
                dataStream: dataStreamName,
                bytes: byteCount
            )
            try throughput.insert(db)
        }
    }
    
}
