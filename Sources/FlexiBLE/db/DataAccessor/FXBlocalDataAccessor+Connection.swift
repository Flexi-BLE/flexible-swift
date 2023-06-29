//
//  FXBlocalDataAccessor+Connection.swift
//  
//
//  Created by Blaine Rothrock on 1/18/23.
//

import Foundation
import GRDB

// MARK: - Public
extension FXBLocalDataAccessor {
    
    public class DeviceAccess {
        
        private var connection: DatabaseWriter
        
        internal init(conn: DatabaseWriter) {
            self.connection = conn
        }
        
        public func getRecords(conncetedOnly: Bool = false) async throws -> [FXBDeviceRecord] {
            return try await connection.read({ db in
                if conncetedOnly {
                    return try FXBDeviceRecord
                        .filter(Column(FXBDeviceRecord.CodingKeys.disconnectedAt.stringValue) == nil)
                        .order(Column(FXBDeviceRecord.CodingKeys.connectedAt).desc)
                        .fetchAll(db)
                } else {
                    return try FXBDeviceRecord
                        .order(Column(FXBDeviceRecord.CodingKeys.connectedAt).desc)
                        .fetchAll(db)
                }
            })
        }
        
        public func getLastRefTime(for deviceType: String, with role: FlexiBLEDeviceRole) async throws -> Date? {
            return try await connection.read({ db in
                return try FXBDeviceRecord
                    .filter(Column(FXBDeviceRecord.CodingKeys.disconnectedAt.stringValue) == nil) // connected
                    .filter(Column(FXBDeviceRecord.CodingKeys.deviceType.stringValue) == deviceType)
                    .filter(Column(FXBDeviceRecord.CodingKeys.role.stringValue) == Int(role.rawValue))
                    .order(Column(FXBDeviceRecord.CodingKeys.referenceEpoch).desc)
                    .fetchOne(db)?.referenceDate
            })
        }
        
        public func getFollowers(for deviceType: String) async throws -> [FXBDeviceRecord] {
            return try await connection.read({ db in
                return try FXBDeviceRecord
                    .filter(Column(FXBDeviceRecord.CodingKeys.disconnectedAt.stringValue) == nil)
                    .filter(Column(FXBDeviceRecord.CodingKeys.deviceType.stringValue) == deviceType)
                    .filter(Column(FXBDeviceRecord.CodingKeys.role.stringValue) == Int(FlexiBLEDeviceRole.metroFollower.rawValue))
                    .fetchAll(db)
            })
        }
    }
}

// MARK: - Internal
internal extension FXBLocalDataAccessor.DeviceAccess {
    func device(id: Int64?) -> FXBDeviceRecord? {
        guard let id = id else { return nil }
        return try? connection.read({ db in
            return try FXBDeviceRecord.fetchOne(db, key: id)
        })
    }
    
    
    func updateOrphandedConnectionRecords() throws {
        try connection.write({ db in
            let sql = """
                UPDATE \(FXBDeviceRecord.databaseTableName)
                SET \(FXBDeviceRecord.CodingKeys.disconnectedAt.stringValue) = :date
                WHERE \(FXBDeviceRecord.CodingKeys.disconnectedAt.stringValue) IS NULL;
            """
            
            try db.execute(sql: sql, arguments: ["date": Date.now.SQLiteFormat()])
        })
    }
    
    func updateFollers(referenceDate: Date, deviceType: String) throws {
        try connection.write({ db in
            let sql = """
                UPDATE \(FXBDeviceRecord.databaseTableName)
                SET \(FXBDeviceRecord.CodingKeys.referenceEpoch.stringValue) = :epoch
                WHERE \(FXBDeviceRecord.CodingKeys.role.stringValue) = :roleRawValue
                    AND \(FXBDeviceRecord.CodingKeys.deviceType.stringValue) = :deviceType
            """
            
            try db.execute(
                sql: sql,
                arguments: [
                    "epoch": referenceDate.timeIntervalSince1970 as Double,
                    "roleRawValue": FlexiBLEDeviceRole.metroFollower.rawValue,
                    "deviceType": deviceType
                ]
            )
        })
    }
    
    func upsert(device: inout FXBDeviceRecord) throws {
        try connection.write({ db in
            try device.upsert(db)
        })
    }
    
}
