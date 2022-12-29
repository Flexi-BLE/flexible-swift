//
//  FXBSpecDataStream.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public class FXBSpecDataStream: Codable {
    public let id: UUID
    public let name, dataStreamDescription: String
    public let precision: FXBSpecDataStreamPrecision
    private var _configValues: [String:FXBSpecValue]
    private var _dataValues: [String:FXBSpecValue]
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
        self._configValues = [:]
        self._dataValues = [:]
        self.dataValueHeirarchy = FXBSpecDataStreamHeirarchy(independents: [], dependents: [:])
        self.writeDefaultsOnConnect = writeDefaultOnConnect
        self.ble = FXBSpecDataStreamBLE()
    }
    
    public var dataValues: [FXBSpecValue] {
        return self._dataValues.values.sorted(by: { $0.index < $1.index })
    }
    
    public var dataValueKeys: [String] {
        return Array(self._dataValues.keys)
    }
    
    public func dataValue(forKey key: String) -> FXBSpecValue? {
        return self._dataValues[key]
    }
    
    public var configValues: [FXBSpecValue] {
        return self._configValues.values.sorted(by: { $0.index < $1.index })
    }
    
    public var configValueKeys: [String] {
        return Array(self._configValues.keys)
    }
    
    public func configValue(forKey key: String) -> FXBSpecValue? {
        return self._configValues[key]
    }
    
    public func addDataValue(_ value: FXBSpecValue, forKey name: String, dependsOn: String?=nil) {
        self._dataValues[name] = value
        if let dependsOn = dependsOn {
            dataValueHeirarchy.addDependent(value.name, dependsOn: dependsOn)
        } else {
            dataValueHeirarchy.addIndependent(value.name)
        }
    }
    
    public func addConfigValue(_ value: FXBSpecValue, forKey name: String) {
        self._configValues[name] = value
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case dataStreamDescription = "description"
        case precision
        case _configValues = "config_values"
        case dataValueHeirarchy = "data_value_heirarchy"
        case _dataValues = "data_values"
        case ble
        case writeDefaultsOnConnect = "write_defaults_on_connect"
    }
}

public enum FXBSpecDataStreamPrecision: String, Codable {
    case millisecond = "ms"
    case microsecond = "us"
}

public class FXBSpecDataStreamHeirarchy: Codable {
    private(set) var independents: [String]
    private(set) var dependents: [String:[String]]
    
    init(independents: [String]=[], dependents: [String:[String]]=[:]) {
        self.independents = independents
        self.dependents = dependents
    }
    
    func addIndependent(_ independent: String) {
        self.independents.append(independent)
    }
    
    func addDependent(_ value: String, dependsOn: String) {
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

    internal enum CodingKeys: String, CodingKey {
        case serviceUUID = "service_uuid"
        case dataCharUUID = "data_characteristic_uuid"
        case configCharUUID = "config_characteristic_uuid"
    }
}
