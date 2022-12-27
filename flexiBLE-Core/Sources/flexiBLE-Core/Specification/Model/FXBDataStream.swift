//
//  FXBSpecDataStream.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public struct FXBSpecDataStream: Codable {
    public let id: UUID
    public let name, dataStreamDescription: String
    public let precision: FXBSpecDataStreamPrecision
    private(set) var configValues: [String:FXBSpecValue]
    private(set) var dataValues: [String:FXBSpecValue]
    private(set) var dataValueHeirarchy: FXBSpecDataStreamHeirarchy
    internal let ble: FXBSpecDataStreamBLE
    public let writeDefaultsOnConnect: Bool
    
    public init(
        name: String,
        description: String?=nil,
        precision: FXBSpecDataStreamPrecision = .millisecond,
        writeDefaultOnConnect: Bool=false
    ) {
        self.id = UUID()
        self.name = name
        self.dataStreamDescription = description ?? ""
        self.precision = precision
        self.configValues = [:]
        self.dataValues = [:]
        self.dataValueHeirarchy = FXBSpecDataStreamHeirarchy(independents: [], dependents: [:])
        self.writeDefaultsOnConnect = writeDefaultOnConnect
        self.ble = FXBSpecDataStreamBLE()
    }
    
    public mutating func addDataValue(_ value: FXBSpecValue, forKey name: String, dependsOn: String?=nil) {
        self.dataValues[name] = value
        if let dependsOn = dependsOn {
            dataValueHeirarchy.addDependent(value.name, dependsOn: dependsOn)
        } else {
            dataValueHeirarchy.addIndependent(value.name)
        }
    }
    
    public mutating func addConfigValue(_ value: FXBSpecValue, forKey name: String) {
        self.configValues[name] = value
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case dataStreamDescription = "description"
        case precision
        case configValues = "config_values"
        case dataValueHeirarchy = "data_value_heirarchy"
        case dataValues = "data_values"
        case ble
        case writeDefaultsOnConnect = "write_defaults_on_connect"
    }
}

public enum FXBSpecDataStreamPrecision: String, Codable {
    case millisecond = "ms"
    case microsecond = "us"
}

public struct FXBSpecDataStreamHeirarchy: Codable {
    private(set) var independents: [String]
    private(set) var dependents: [String:[String]]
    
    mutating func addIndependent(_ independent: String) {
        self.independents.append(independent)
    }
    
    mutating func addDependent(_ value: String, dependsOn: String) {
        if dependents[dependsOn] == nil {
            dependents[dependsOn] = []
        }
        
        self.dependents[dependsOn]!.append(value)
    }
}

internal class FXBSpecDataStreamBLE: Codable {
    let serviceUUID, dataCharUUID, configCharUUID: UUID
    
    init() {
        self.serviceUUID = UUID()
        self.dataCharUUID = UUID()
        self.configCharUUID = UUID()
    }
    
    init(serviceUUID: UUID, dataUUID: UUID, configUUID: UUID) {
        self.serviceUUID = serviceUUID
        self.dataCharUUID = dataUUID
        self.configCharUUID = configUUID
    }

    enum CodingKeys: String, CodingKey {
        case serviceUUID = "service_uuid"
        case dataCharUUID = "data_characteristic_uuid"
        case configCharUUID = "config_characteristic_uuid"
    }
}
