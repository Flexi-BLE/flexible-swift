//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/11/23.
//

import Foundation

public class FXBTableUploader {
    var table: FXBUploadableTable
    var startDate: Date?
    var endDate: Date
    
    var credentials: InfluxDBCredentials
    
    private var calculatedUploadCount = 0
    var totalRemaining: Int = 0
    var uploaded: Int = 0
    
    var complete: Bool = false
    var errorMessage: String? = nil
    
    private var uploadTime: TimeInterval = 0
    private var numberOfAPICalls: Int = 0
    private var totalBytes: Int = 0
    
    init(
        table: FXBUploadableTable,
        credentials: InfluxDBCredentials,
        startDate: Date?,
        endDate: Date
    ) {
        self.table = table
        self.credentials = credentials
        self.startDate = startDate
        self.endDate = endDate
        
        Task {
            await calculateRecordCount()
        }
    }
    
    private func nextRecords() async -> [ILPRecord] {
        do {
            return try await table.ILPQuery(
                from: startDate,
                to: endDate,
                uploaded: false,
                limit: credentials.batchSize,
                deviceId: credentials.deviceId
            )
        } catch {
            complete = true
            let message = "error querying records: \(error.localizedDescription)"
            errorMessage = message
            uploadLog.error("\(message)")
            await save()
            return []
        }
    }
    
    func upload() async -> Result<Bool, Error> {
        let start = Date.now
        
        dbLog.debug("data upload: starting upload for \(self.table.tableName) (\(self.totalRemaining))")
        
        var records = await nextRecords()
        
        guard !records.isEmpty else {
            complete = true
            return .success(true)
        }
        
        while !records.isEmpty {
            let res = await records.ship(with: credentials)
            numberOfAPICalls += 1
            switch res {
            case .success(_):
                
                dbLog.error("data upload: successfully upload \(records.count) records")
                
                totalRemaining -= records.count
                uploaded += records.count
                totalBytes += records.reduce(0, { $0 + Data($1.line.utf8).count })
                
                await updateUploadedFlag(records: records)
                
                records = await nextRecords()
                
            case .failure(let error):
                complete = true
                errorMessage = error.localizedDescription
                uploadTime = abs(start.timeIntervalSinceNow)
                await save()
                return res
            }
        }
        
        complete = true
        if credentials.purgeOnUpload {
            await purgeUploaded()
        }
        uploadTime = abs(start.timeIntervalSinceNow)
        await save()
        return .success(true)
    }
    
    private func updateUploadedFlag(records: [ILPRecord]) async {
        do {
            try await table.updateUpload(lines: records)
            uploadLog.info("updated database records")
        } catch {
            errorMessage = "error updating uploaded flag: error \(error.localizedDescription)"
            uploadLog.error("failed to update database records uploaded = true")
        }
    }
    
    private func purgeUploaded() async {
        do {
            try await table.purgeUploadedRecords()
        } catch {
            errorMessage = "unable to purge records: \(error.localizedDescription)"
        }
    }
    
    private func calculateRecordCount() async {
        do {
            var recordCount: Int = try await FlexiBLE.shared
                .dbAccess?
                .timeseries
                .count(
                    for: table,
                    start: startDate,
                    end: endDate,
                    deviceName: nil,
                    uploaded: false
                ) ?? 0
            
            
            
            if recordCount == 0 {
                complete = true
                return
            }
            totalRemaining = recordCount
            calculatedUploadCount = recordCount
            uploaded = 0
        } catch {
            totalRemaining = 0
            uploaded = 0
            complete = true
            errorMessage = "unable to obtain record count, \(error.localizedDescription)"
            await save()
        }
    }
    
    private func save() async {
        do {
            var record = FXBDataUpload(
                ts: Date.now,
                tableName: self.table.tableName,
                database: "influxDB",
                APIURL: self.credentials.url.absoluteString,
                startDate: self.startDate,
                endDate: self.endDate,
                expectedUploadCount: self.calculatedUploadCount,
                uploadCount: self.uploaded,
                errorMessage: errorMessage,
                uploadTimeSeconds: self.uploadTime,
                numberOfAPICalls: self.numberOfAPICalls,
                totalBytes: self.totalBytes
            )
            
            try FlexiBLE.shared.dbAccess?.dataUpload.record(&record)
        } catch {
            uploadLog.error("error inserting upload record: \(error.localizedDescription)")
        }
    }
}
