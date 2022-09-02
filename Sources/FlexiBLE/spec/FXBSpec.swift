//
//  FXBDeviceConfig.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct FXBSpec: Codable {
    public let id: String
    public let schemaVersion: String
    public let createdAt: Date
    public let updatedAt: Date
    public let tags: [String]
    public let bleRegisteredDevices: [FXBRegisteredDevice]
    public let devices: [FXBDevice]
}

extension FXBSpec {
    public static var mock: FXBSpec {
        return Bundle.module.decode(FXBSpec.self, from: "exthub.json")
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
            let (data, _) = try await URLSession.shared.data(from: url)
            let config = try Data.sharedJSONDecoder.decode(FXBSpec.self, from: data)
            return config
        } catch {
            gLog.debug("unable to download Device Config from \(url.absoluteURL)")
            return nil
        }
    }
}