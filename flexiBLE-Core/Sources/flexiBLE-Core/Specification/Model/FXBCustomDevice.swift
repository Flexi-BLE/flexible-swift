//
//  FXBSpecCustomDevice.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public struct FXBSpecCustomDevice: Codable, Identifiable {
    public let id: UUID
    public let name, customDeviceDescription: String
    private(set) var registeredGattServices: [FXBSpecRegisteredGATTService]
    public let writeDelayMS: Int
    private(set) var dataStreams: [String:FXBSpecDataStream]
    
    public init(name: String, description: String?=nil, registeredGattServices: [FXBSpecRegisteredGATTService]?=nil, writeDelayMS: Int=500) {
        
        self.id = UUID()
        self.name = name
        self.customDeviceDescription = description ?? ""
        self.registeredGattServices = registeredGattServices ?? []
        self.writeDelayMS = writeDelayMS
        self.dataStreams = [:]
    }
    
    public mutating func add(_ dataStream: FXBSpecDataStream, forKey name: String) {
        dataStreams[name] = dataStream
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case customDeviceDescription = "description"
        case registeredGattServices = "registered_gatt_services"
        case writeDelayMS = "write_delay_ms"
        case dataStreams = "data_streams"
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
