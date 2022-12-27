//
//  FlexiBLESpecification.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

/// Top level FlexiBLE Specification, which defines groupings of FlexiBLE enabled devices
///
/// - Author: Blaine Rothrock
/// - Version: 0.4.0
public class FXBSpecification: Codable {
    
    public let id: UUID
    let name, schemaVersion: String
    private(set) var version: Int
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var author: FXBSpecAuthor
    private var _gattDevices: [String:FXBSpecGattDevice]
    private var _customDevices: [String:FXBSpecCustomDevice]
    
    public init(name: String, author: FXBSpecAuthor) {
        self.id = UUID()
        self.name = name
        self.schemaVersion = "0.4.0"
        self.version = 1
        self.createdAt = Date()
        self.updatedAt = Date()
        self.author = author
        self._gattDevices = [:]
        self._customDevices = [:]
    }
    
    public func add(_ device: FXBSpecCustomDevice, forKey name: String) {
        self._customDevices[name] = device
    }
    
    public func add(_ device: FXBSpecGattDevice, forKey name: String) {
        self._gattDevices[name] = device
    }
    
    public func removeCustomDevice(forKey key: String) {
        self._customDevices[key] = nil
    }
    
    public func removeGattDevice(forKey key: String) {
        self._gattDevices[key] = nil 
    }
    
    public var customDevices: [FXBSpecCustomDevice] {
        return Array(_customDevices.values)
    }
    
    public var gattDevices: [FXBSpecGattDevice] {
        return Array(_gattDevices.values)
    }
    
    public var customDeviceKeys: [String] {
        return Array(self._customDevices.keys)
    }
    
    public var gattDeviceKeys: [String] {
        return Array(self._gattDevices.keys)
    }
    
    public func customDevice(forKey key: String) -> FXBSpecCustomDevice? {
        return self._customDevices[key]
    }
    
    public func gattDevice(forKey key: String) -> FXBSpecGattDevice? {
        return self._gattDevices[key]
    }

    internal enum CodingKeys: String, CodingKey {
        case id, name
        case schemaVersion = "schema_version"
        case version = "spec_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author
        case _gattDevices = "gatt_devices"
        case _customDevices = "custom_devices"
    }
}

extension FXBSpecification: Equatable, Hashable {
    public static func == (lhs: FXBSpecification, rhs: FXBSpecification) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
