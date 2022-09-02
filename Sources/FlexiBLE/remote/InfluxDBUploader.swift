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
    
    public init(
        url: URL,
         org: String,
         bucket: String,
         token: String,
         batchSize: Int=1000
    ) {
        self.url = url
        self.org = org
        self.bucket = bucket
        self.token = token
        self.batchSize = batchSize
        self.state = .notStarted
        self.progress = 0.0
        self.estNumRecs = 0
        self.totalUploaded = 0
        
        tableStatuses = [
            FXBTableUploadState(table: FXBConnection.databaseTableName, isStatic: true),
            FXBTableUploadState(table: FXBExperiment.databaseTableName, isStatic: true),
            FXBTableUploadState(table: FXBTimestamp.databaseTableName, isStatic: true),
            FXBTableUploadState(table: FXBHeartRate.databaseTableName, isStatic: true),
            FXBTableUploadState(table: FXBLocation.databaseTableName, isStatic: true)
        ]
    }
    
    public func start() {
        Task {
            do {
                self.state = .initializing
                await addDynamicTableStates()
                try await calculateRemaining()
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
            if tableStatuses.first(where: { $0.table == tn }) == nil {
                tableStatuses.append(FXBTableUploadState(table: tn, isStatic: false))
            }
        }
    }
    
    private func continuousUpload() async throws {
//        while self.state == .running, self.estNumRecs > 0 {
//
//            try await calculateRemaining()
//        }
    }
    
    private func calculateRemaining() async throws {
        var tmpTotal = 0
        for status in tableStatuses {
            let st = try await FXBRead().getTotalRecords(
                for: status.table,
                from: nil,
                to: nil,
                uploaded: false
            )
            status.totalRemaining = st
            tmpTotal += st
        }
        
        self.estNumRecs = tmpTotal
    }
    
    
}
