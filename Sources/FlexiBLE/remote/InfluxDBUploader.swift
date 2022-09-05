//
//  InfluxDBUploader.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation
import GRDB

public class InfluxDBUploader: FXBRemoteDatabaseUploader, ObservableObject {
    @Published public var state: FXBDataUploaderState
    public var stateValue: Published<FXBDataUploaderState> { return _state }
    public var statePublisher: Published<FXBDataUploaderState>.Publisher { return $state }
    
    @Published public private(set) var progress: Float
    public var progressValue: Published<Float> {
        return _progress
    }
    public var progressPublisher: Published<Float>.Publisher {
        return $progress
    }
    
    @Published public private (set) var estNumRecs: Int
    public var estNumRecsValue: Published<Int> { return _estNumRecs }
    public var estNumRecsPublisher: Published<Int>.Publisher { return $estNumRecs }
    
    @Published public var totalUploaded: Int {
        didSet {
            self.progress = Float(totalUploaded) / Float(estNumRecs)
        }
    }
    public var totalUploadedValue: Published<Int> { return _totalUploaded }
    public var totalUploadedPublisher: Published<Int>.Publisher { return $totalUploaded }
    
    public var batchSize: Int
    public var tableStatuses: [FXBTableUploadState]
    
    private let url: URL
    private let org: String
    private let bucket: String
    private let token: String
    
    public let startDate: Date?
    public let endDate: Date?
    
    public let deviceId: String
    
    public init(
        url: URL,
        org: String,
        bucket: String,
        token: String,
        startDate: Date?=nil,
        endDate: Date?=nil,
        batchSize: Int=50,
        deviceId: String
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
                DispatchQueue.main.async {
                    self.state = .initializing
                }
                
                await addDynamicTableStates()
                
                let numRemaining = try await calculateRemaining()
                
                DispatchQueue.main.async {
                    self.estNumRecs = numRemaining
                    self.state = .running
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(msg: "error initializing upload: \(error.localizedDescription)")
                }
            }
            
            do {
                try await continuousUpload()
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(msg: "error in record upload: \(error.localizedDescription)")
                }
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
                tableStatuses.append(FXBTableUploadState(table: .dynamic(name: tn)))
            }
        }
    }
    
    private func continuousUpload() async throws {
        while self.state == .running {
            if let tableStatus = tableStatuses.first(where: { $0.totalRemaining > 0 }) {
                do {
                    let records = try await tableStatus.table.ILPQuery(from: startDate, to: endDate, uploaded: false, limit: batchSize, deviceId: deviceId)
                    
                    let success = try await records.ship(
                        url: url,
                        org: org,
                        bucket: bucket,
                        token: token
                    )
                    
                    guard success else {
                        DispatchQueue.main.async {
                            self.state = .error(msg: "unable to upload records")
                        }
                        return
                    }
                    
                    try await tableStatus.table.updateUpload(lines: records)
                    
                    tableStatus.uploaded += records.count
                    tableStatus.totalRemaining -= records.count
                    
                    DispatchQueue.main.async {
                        self.totalUploaded += records.count
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.state = .error(msg: "error querying records for \(tableStatus.table.tableName): error \(error.localizedDescription)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.state = .done
                }
            }
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
