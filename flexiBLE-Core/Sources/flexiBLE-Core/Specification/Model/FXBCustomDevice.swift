//
//  FXBSpecCustomDevice.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public class FXBSpecCustomDevice: Codable, Identifiable {
    public let id: UUID
    public let name, customDeviceDescription: String
    private(set) var registeredGattServices: [FXBSpecRegisteredGATTService]
    public let writeDelayMS: Int
    private var _dataStreams: [String:FXBSpecDataStream]
    
    public init(name: String, description: String?=nil, registeredGattServices: [FXBSpecRegisteredGATTService]?=nil, writeDelayMS: Int=500) {
        
        self.id = UUID()
        self.name = name
        self.customDeviceDescription = description ?? ""
        self.registeredGattServices = registeredGattServices ?? []
        self.writeDelayMS = writeDelayMS
        self._dataStreams = [:]
    }
    
    public var dataStreams: [FXBSpecDataStream] {
        return Array(_dataStreams.values)
    }
    
    public var dataStreamKeys: [String] {
        return Array(_dataStreams.keys)
    }
    
    public func dataStream(forKey key: String) -> FXBSpecDataStream? {
        return _dataStreams[key]
    }
    
    public func removeDataSteam(forKey key: String) {
        self._dataStreams[key] = nil
    }
    
    public func add(_ dataStream: FXBSpecDataStream, forKey name: String) {
        _dataStreams[name] = dataStream
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case customDeviceDescription = "description"
        case registeredGattServices = "registered_gatt_services"
        case writeDelayMS = "write_delay_ms"
        case _dataStreams = "data_streams"
    }
}

extension FXBSpecCustomDevice: Hashable, Equatable {
    public static func == (lhs: FXBSpecCustomDevice, rhs: FXBSpecCustomDevice) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Defines a Custom FlexiBLE device BLE specifics
internal struct FXBSpecCustomDeviceBLE: Codable {
    let bleRegisteredServices: [FXBSpecRegisteredGATTService]
    
    let infoServiceUUID, epochCharUUID, specVersionCharUUID, specIDCharUUID: String
    let refreshEpochCharUUID: String

    enum CodingKeys: String, CodingKey {
        case bleRegisteredServices = "ble_registered_services"
        case infoServiceUUID = "info_service_uuid"
        case epochCharUUID = "epoch_char_uuid"
        case specVersionCharUUID = "spec_version_char_uuid"
        case specIDCharUUID = "spec_id_char_uuid"
        case refreshEpochCharUUID = "refresh_epoch_char_uuid"
    }
}
