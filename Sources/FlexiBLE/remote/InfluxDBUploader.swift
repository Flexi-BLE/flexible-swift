//
//  InfluxDBUploader.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation
import GRDB
import os

public class InfluxDBUploader: FXBRemoteDatabaseUploader {
    public var state: FXBDataUploaderState
    
    public private(set) var progress: Float
    
    public private (set) var estNumRecs: Int
    
    private let logger = Logger(subsystem: "com.blainerothrock.flexible", category: "uploader")
    
    public var totalUploaded: Int {
        didSet {
            self.progress = Float(totalUploaded) / Float(estNumRecs)
        }
    }
    
    public private (set) var statusMessage: String
    
    public var batchSize: Int
    public var tableStatuses: [FXBTableUploadState]
    
    private let url: URL
    private let org: String
    private let bucket: String
    private let token: String
    
    public let startDate: Date?
    public let endDate: Date?
    
    public let deviceId: String
    
    public let purgeOnUpload: Bool
    
    public init(
        url: URL,
        org: String,
        bucket: String,
        token: String,
        startDate: Date?=nil,
        endDate: Date?=nil,
        batchSize: Int=2500,
        deviceId: String,
        purgeOnUpload: Bool = false
    ) {
        self.url = url
        self.org = org
        self.bucket = bucket
        self.token = token
        self.startDate = startDate
        self.endDate = endDate
        self.batchSize = batchSize
        self.state = .notStarted
        self.progress = 0.0
        self.estNumRecs = 0
        self.totalUploaded = 0
        self.deviceId = deviceId
        self.statusMessage = ""
        self.purgeOnUpload = purgeOnUpload
        
        tableStatuses = [
            FXBTableUploadState(table: .experiment),
            FXBTableUploadState(table: .timestamp),
            FXBTableUploadState(table: .heartRate),
            FXBTableUploadState(table: .location)
        ]
    }
    
    public func start() {
        Task {
            do {
                self.state = .initializing
                
                await addDynamicTableStates()
                
                let numRemaining = try await calculateRemaining()
                
                self.estNumRecs = numRemaining
                self.state = .running
            } catch {
                self.state = .error(msg: "error initializing upload: \(error.localizedDescription)")
            }
            
            do {
                try await continuousUpload()
            } catch {
                self.state = .error(msg: "error in record upload: \(error.localizedDescription)")
            }
        }
    }
    
    public func pause() {
        self.state = .paused
    }
    
    private func addDynamicTableStates() async {
        let dtns = await FXBRead().dynamicTableNames()
        for tn in dtns {
            if tableStatuses.first(where: { $0.table.tableName == tn }) == nil {
                tableStatuses.append(FXBTableUploadState(table: .dynamicData(name: "\(tn)_data")))
                tableStatuses.append(FXBTableUploadState(table: .dynamicConfig(name: "\(tn)_config")))
            }
        }
    }
    
    private func continuousUpload() async throws {
        while self.state == .running {
            if let tableStatus = tableStatuses.first(where: { $0.totalRemaining > 0 }) {
                DispatchQueue.main.async {
                    self.statusMessage = "Uploading \(tableStatus.table.tableName) ..."
                }
                
                do {
                    logger.info("starting upload for \(tableStatus.table.tableName)")
                    let records = try await tableStatus.table.ILPQuery(
                        from: startDate,
                        to: endDate,
                        uploaded: false,
                        limit: batchSize,
                        deviceId: deviceId
                    )
                    logger.info("\(records.count) records found")
                    
                    if records.count == 0 {
                        tableStatus.totalRemaining = 0
                    }
                    
                    let success = try await records.ship(
                        url: url,
                        org: org,
                        bucket: bucket,
                        token: token
                    )
                    
                    logger.info("upload success?: \(success)")
                    
                    guard success else {
                        self.state = .error(msg: "unable to upload records")
                        let _ = try await FXBWrite().recordUpload(
                            success: false,
                            byteSize: 0,
                            numberOfRecords: records.count,
                            bucket: self.bucket,
                            measurement: records.first?.measurement ?? tableStatus.table.tableName,
                            errorMessage: "unable to upload records"
                        )
                        tableStatus.totalRemaining = 0
                        return
                    }
                    
                    if records.count > 0 {
                        await updateUploaded(records: records, tableStatus: tableStatus)
                        let _ = try await FXBWrite().recordUpload(
                            success: true,
                            byteSize: records.reduce(0, { $0 + $1.line.lengthOfBytes(using: .utf8) }),
                            numberOfRecords: records.count,
                            bucket: bucket,
                            measurement: records.first?.measurement ?? tableStatus.table.tableName,
                            errorMessage: nil
                        )
                    } else {
                        tableStatus.totalRemaining = 0
                    }
                    
                } catch {
                    self.state = .error(msg: "error querying records for \(tableStatus.table.tableName): error \(error.localizedDescription)")
                    let _ = try? await FXBWrite().recordUpload(
                        success: false,
                        byteSize: 0,
                        numberOfRecords: 0,
                        bucket: nil,
                        measurement: nil,
                        errorMessage: "error querying records for \(tableStatus.table.tableName): error \(error.localizedDescription)"
                    )
                    tableStatus.totalRemaining = 0
                }
            } else {
                self.state = .done
            }
        }
    }
    
    private func updateUploaded(records: [ILPRecord], tableStatus: FXBTableUploadState) async {
        do {
            try await tableStatus.table.updateUpload(lines: records)
            
            if purgeOnUpload {
                try await tableStatus.table.purgeUploadedRecords()
            }
            
            tableStatus.uploaded += records.count
            tableStatus.totalRemaining -= records.count
            
            self.totalUploaded += records.count
            
            logger.info("updated database records")
        } catch {
            self.state = .error(msg: "error updating uploaded state for \(tableStatus.table.tableName): error \(error.localizedDescription)")
            logger.error("failed to update database records")
        }
    }
    
    private func calculateRemaining() async throws -> Int{
        var tmpTotal = 0
        for status in tableStatuses {
            let st = try await FXBRead().getTotalRecords(
                for: status.table.tableName,
                from: startDate,
                to: endDate,
                uploaded: false
            )
            status.totalRemaining = st
            tmpTotal += st
        }
        
        return tmpTotal
    }
}
