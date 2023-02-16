//
//  FXBDeviceConfig.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public class FXBSpec: Codable {
    public let id: String
    public let schemaVersion: String
    public let createdAt: Date
    public let updatedAt: Date
    public var bleRegisteredDevices: [FXBRegisteredDeviceSpec]
    public var devices: [FXBDeviceSpec]
    
    public static let schemaVersion = "0.3.7"
    
    init(id: String, schemaVersion: String, createdAt: Date, updatedAt: Date, bleRegisteredDevices: [FXBRegisteredDeviceSpec], devices: [FXBDeviceSpec]) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bleRegisteredDevices = bleRegisteredDevices
        self.devices = devices
    }
    
    @discardableResult
    public func add(device: FXBDeviceSpec) -> FXBSpec {
        self.devices.append(device)
        return self
    }
    
    @discardableResult
    public func add(device: FXBRegisteredDeviceSpec) -> FXBSpec {
        self.bleRegisteredDevices.append(device)
        return self
    }
}

extension FXBSpec {
    public static var mock: FXBSpec {
        return Bundle.module.decode(FXBSpec.self, from: "flexible-sample.json")
    }
    
    public static func load(from fileName: String) -> FXBSpec? {
        do {
            if let url = Bundle.module.url(forResource: fileName, withExtension: nil) {
                let data = try Data(contentsOf: url)
                let config = try Data.sharedJSONDecoder.decode(FXBSpec.self, from: data)
                return config
            } else { return nil }
        } catch {
            return nil
        }
    }
    
    public static func load(from url: URL) async throws -> FXBSpec? {
        do {
            let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            let (data, _) = try await URLSession.shared.data(for: req)
            let config = try Data.sharedJSONDecoder.decode(FXBSpec.self, from: data)
            return config
        } catch {
            gLog.debug("unable to download Device Config from \(url.absoluteURL), error: \(error.localizedDescription)")
            return nil
        }
    }
}
