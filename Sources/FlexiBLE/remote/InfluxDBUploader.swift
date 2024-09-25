//
//  InfluxDBUploader.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation
import GRDB
import os

public class InfluxDBCredentials {
    public var url: URL
    public var org: String
    public var bucket: String
    internal var token: String
    public var batchSize: Int
    public var deviceId: String
    public var uploadInterval: TimeInterval?
    public var maxLookback: TimeInterval?
    public var purgeOnUpload: Bool
    
    public init(
        url: URL,
        org: String,
        bucket: String,
        token: String,
        batchSize: Int,
        deviceId: String,
        purgeOnUpload: Bool,
        uploadInterval: TimeInterval?,
        maxLookback: TimeInterval?
    ) {
        self.url = url
        self.org = org
        self.bucket = bucket
        self.token = token
        self.batchSize = batchSize
        self.deviceId = deviceId
        self.purgeOnUpload = purgeOnUpload
        self.uploadInterval = uploadInterval
        self.maxLookback = maxLookback
    }
}

public class InfluxDBUploader: FXBRemoteDatabaseUploader {
    
    public var state: FXBDataUploaderState
    
    public private(set) var progress: Float
    
    public private (set) var estNumRecs: Int
    
    public var totalUploaded: Int {
        didSet {
            self.progress = Float(totalUploaded) / Float(estNumRecs)
        }
    }
    
    public private (set) var statusMessage: String
    
    public var tableUploaders: [FXBTableUploader]
    
    private let credentials: InfluxDBCredentials
    
    public let startDate: Date?
    public let endDate: Date
    
    public init(
        credentials: InfluxDBCredentials,
        startDate: Date?=nil,
        endDate: Date=Date.now
    ) {
        self.credentials = credentials
        self.startDate = startDate
        self.endDate = endDate
        self.state = .notStarted
        self.progress = 0.0
        self.estNumRecs = 0
        self.totalUploaded = 0
        self.statusMessage = ""
        
        tableUploaders = [
            FXBTableUploader(table: .experiment, credentials: credentials, startDate: startDate, endDate: endDate),
            FXBTableUploader(table: .timestamp, credentials: credentials, startDate: startDate, endDate: endDate),
            FXBTableUploader(table: .heartRate, credentials: credentials, startDate: startDate, endDate: endDate),
            FXBTableUploader(table: .location, credentials: credentials, startDate: startDate, endDate: endDate),
        ]
    }
    
    public func upload() async -> Result<Bool, Error> {
        self.state = .initializing
        
        await addDynamicTableStates()
        
        let numRemaining = tableUploaders.reduce(0, { $0 + $1.totalRemaining })
        
        self.estNumRecs = numRemaining
        self.state = .running
        
        do {
            try await continuousUpload()
            return .success(true)
        } catch {
            self.state = .error(msg: "error in record upload: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func pause() {
        self.state = .paused
    }
    
    private func addDynamicTableStates() async {
        let dtns = try? FlexiBLE.shared
            .dbAccess?
            .dynamicTable
            .tableNames() ?? []
        
        for tn in dtns ?? [] {
            if tableUploaders.first(where: { $0.table.tableName == tn }) == nil {
                tableUploaders.append(FXBTableUploader(
                    table: .dynamicData(name: tn),
                    credentials: credentials,
                    startDate: startDate,
                    endDate: endDate
                ))
                tableUploaders.append(FXBTableUploader(
                    table: .dynamicConfig(name: tn),
                    credentials: credentials,
                    startDate: startDate,
                    endDate: endDate
                ))
            }
        }
    }
    
    private func continuousUpload() async throws {
        while self.state == .running {
            
            for uploader in tableUploaders {
                guard !uploader.complete else { continue }
                let res = await uploader.upload()
                switch res {
                case .success(_): continue
                case .failure(let error):
                    self.statusMessage = error.localizedDescription
                    // self.state = .error(msg: error.localizedDescription)
                }
                
            }
            
            self.state = .done
        }
    }
}
