//
//  InfluxDBUploader.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation
import GRDB

internal class InfluxDBUploader: FXBRemoteDatabaseUploader, ObservableObject {
    @Published var state: FXBDataUploaderState
    var stateValue: Published<FXBDataUploaderState> { return _state }
    var statePublisher: Published<FXBDataUploaderState>.Publisher { return $state }
    
    @Published private(set) var progress: Float
    var progressValue: Published<Float> {
        return _progress
    }
    var progressPublisher: Published<Float>.Publisher {
        return $progress
    }
    
    @Published private (set) var estNumRecs: Int
    var estNumRecsValue: Published<Int> { return _estNumRecs }
    var estNumRecsPublisher: Published<Int>.Publisher { return $estNumRecs }
    
    @Published var totalUploaded: Int {
        didSet {
            self.progress = Float(totalUploaded) / Float(estNumRecs)
        }
    }
    var totalUploadedValue: Published<Int> { return _totalUploaded }
    var totalUploadedPublisher: Published<Int>.Publisher { return $totalUploaded }
    
    var batchSize: Int
    var tableStatuses: [FXBTableUploadState]
    
    init(batchSize: Int=1000) {
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
    
    func start() {
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
    
    func pause() {
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
        while self.state == .running, self.estNumRecs > 0 {
            
            try await calculateRemaining()
        }
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
