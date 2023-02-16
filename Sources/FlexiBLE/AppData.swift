//
//  AppData.swift
//  
//
//  Created by Blaine Rothrock on 2/13/23.
//

import Foundation

class FlexiBLEAppData: Codable {
    static var FlexiBLEBasePath: URL {
        guard let path = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
        ).first?.appendingPathComponent("FlexiBLE") else {
            fatalError("unable to access document directory (create FlexiBLE Documents directory)")
        }
        
        return path
    }
    
    static var FlexiBLEAppDataPath: URL {
        return Self.FlexiBLEBasePath.appendingPathComponent("AppData.json")
    }
    
    private static var _shared: FlexiBLEAppData?
    
    static var shared: FlexiBLEAppData {
        if let inst = Self._shared { return inst }
        
        let path = Self.FlexiBLEAppDataPath
        gLog.info("FlexiBLE Application Data File: \(path.absoluteString)")
        
        if !FileManager.default.fileExists(atPath: path.relativePath) {
            let inst = FlexiBLEAppData()
            _shared = inst
            inst.save()
            return inst
        }
        
        do {
            let data = try Data(contentsOf: path)
            let inst = try Data.sharedJSONDecoder.decode(FlexiBLEAppData.self, from: data)
            
            return inst
        } catch {
            return FlexiBLEAppData()
        }
    }
    
    private var lastProfileId: UUID? = nil
    private(set) var profiles: [FlexiBLEProfile] = []
    
    func add(_ profile: FlexiBLEProfile, setLast: Bool = true) {
        self.profiles.append(profile)
        if setLast {
            self.lastProfileId = profile.id
        }
        self.save()
    }
    
    func lastProfile() -> FlexiBLEProfile? {
        if let id = lastProfileId {
            return profiles.first(where: { $0.id == id })
        }
        return nil
    }
    
    func get(id: UUID, setLast: Bool = true) -> FlexiBLEProfile? {
        if let profile = profiles.first(where: { $0.id == id }) {
            if setLast { lastProfileId = id }
            save()
            return profile
        }
        return nil
    }
    
    func save() {
        do {
            let data = try Data.sharedJSONEncoder.encode(self)
            try data.write(to: Self.FlexiBLEAppDataPath)
        } catch {
            pLog.error("Unable to write FlexiBLE Application Data: \(error.localizedDescription)")
        }
    }
    
    internal static func createBasePath(name: String?, id: UUID) -> URL {
        do {
            
            var dir: String
            if let name = name {
                dir = "\(name)_\(id)"
            } else {
                dir = id.uuidString
            }
            
            let path = FlexiBLEAppData.FlexiBLEBasePath
                .appendingPathComponent(dir, isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: path.absoluteString){
                do {
                    try FileManager.default.createDirectory(
                        at: path.absoluteURL,
                        withIntermediateDirectories: true
                    )
                } catch {
                    fatalError("Error creating directory at path: \(path.absoluteString)")
                }
            }
            
            return path
        }
    }
    
    internal static func createTransactionalDatabasesBasePath(basePath: URL) -> URL {
        let path =  basePath.appendingPathComponent(
            "transactional",
            conformingTo: .directory
        )
        
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            do {
                try FileManager.default.createDirectory(
                    at: path,
                    withIntermediateDirectories: true
                )
            } catch {
                fatalError("Error creating directory at path: \(path.absoluteString)")
            }
        }
        
        return path
    }
    
    internal func deleteAppData() throws {
        try FileManager.default.removeItem(at: Self.FlexiBLEBasePath)
    }
}
