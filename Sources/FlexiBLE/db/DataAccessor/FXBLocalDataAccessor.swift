//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation

final public class FXBLocalDataAccessor {
    
    private var db: FXBDatabase
    
    public let connection: ConnectionAccess
    public let dataStreamConfig: DataStreamConfigAccess
    public let dataStream: DataStreamAccess
    public let dynamicTable: DynamicTableAccess
    
    public let experiment: ExperimentAccess
    
    public let heartRate: HeartRateAccess
    public let location: LocationAccess
    public let throughput: ThroughputAccess
    
    public let dataUpload: DataUploadAccess
    
    internal init(db: FXBDatabase) {
        self.db = db
        
        connection = ConnectionAccess(conn: db.mainConnection)
        dataStreamConfig = DataStreamConfigAccess(conn: db.mainConnection, spec: db.spec)
        dataStream = DataStreamAccess(transactionalManager: db.transactionalDBMgr)
        dynamicTable = DynamicTableAccess(conn: db.mainConnection)
        experiment = ExperimentAccess(conn: db.mainConnection)
        heartRate = HeartRateAccess(transactionalManager: db.transactionalDBMgr)
        location = LocationAccess(transactionalManager: db.transactionalDBMgr)
        throughput = ThroughputAccess(transactionalManager: db.transactionalDBMgr)
        dataUpload = DataUploadAccess(transactionalManager: db.transactionalDBMgr)
    }
}
