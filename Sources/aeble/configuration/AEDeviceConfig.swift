//
//  PeripheralMetadataPayload.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

public struct AEDeviceConfig: Codable {
    public let id: String
    public let schemaVersion: String
    public let createdAt: Date
    public let updatedAt: Date
    public let tags: [String]
    public let bleRegisteredDevices: [AEBLERegisteredDevice]
    public let things: [AEThing]
}

extension AEDeviceConfig {
    public static var mock: AEDeviceConfig {
        return Bundle.module.decode(AEDeviceConfig.self, from: "exthub.json")
    }
    
    public static func load(from fileName: String) -> AEDeviceConfig? {
        do {
            if let url = Bundle.module.url(forResource: fileName, withExtension: nil) {
                let data = try Data(contentsOf: url)
                let config = try Data.sharedJSONDecoder.decode(AEDeviceConfig.self, from: data)
                return config
            } else { return nil }
        } catch { return nil }
    }
    
    public static func load(from url: URL) async throws -> AEDeviceConfig? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let config = try Data.sharedJSONDecoder.decode(AEDeviceConfig.self, from: data)
            return config
        } catch {
            gLog.debug("unable to download Device Config from \(url.absoluteURL)")
            return nil
        }
    }
}
