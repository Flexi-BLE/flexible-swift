//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

final public class FXBLocalDataAccessor {
    
    private var db: FXBDatabase
    
    public let device: DeviceAccess
    
    public let dataStreamConfig: DataStreamConfigAccess
    public let dataStream: DataStreamAccess
    public let dynamicTable: DynamicTableAccess
    
    public let experiment: ExperimentAccess
    
    public let heartRate: HeartRateAccess
    public let location: LocationAccess
    public let throughput: ThroughputAccess
    
    public let dataUpload: DataUploadAccess
    
    public let timeseries: TimeSeries
    
    internal init(db: FXBDatabase) {
        self.db = db
        
        device = DeviceAccess(conn: db.mainConnection)
        dataStreamConfig = DataStreamConfigAccess(conn: db.mainConnection, spec: db.spec)
        dataStream = DataStreamAccess(transactionalManager: db.transactionalDBMgr)
        dynamicTable = DynamicTableAccess(conn: db.mainConnection)
        experiment = ExperimentAccess(conn: db.mainConnection)
        heartRate = HeartRateAccess(transactionalManager: db.transactionalDBMgr)
        location = LocationAccess(transactionalManager: db.transactionalDBMgr)
        throughput = ThroughputAccess(transactionalManager: db.transactionalDBMgr)
        dataUpload = DataUploadAccess(transactionalManager: db.transactionalDBMgr)
        timeseries = TimeSeries(transactionManager: db.transactionalDBMgr, mainConnection: db.mainConnection)
    }
}
