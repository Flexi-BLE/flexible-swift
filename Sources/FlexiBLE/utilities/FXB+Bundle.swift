//
//  FXB+Bundle.swift
//  
//
//  Created by blaine on 2/22/22.
//

import Foundation

public extension Bundle {
    var appVersion: String {
        if let ver = self.infoDictionary?["CFBundleShortVersionString"] as? String {
            return ver
        }
        return "unknown version"
    }
    
    var buildNumber: String {
        if let build = self.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "unknown build#"
    }
    
    var os: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #else
        return "Unknown OS"
        #endif
    }
    
    func copyFilesFromBundleToDocumentsFolderWith(fileName: String, in dir:String?=nil) {
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let dir = dir {
            documentsURL?.appendPathComponent(dir, isDirectory: true)
        }
        
        if let documentsURL = documentsURL,
           let sourceURL = self.url(forResource: fileName, withExtension: nil) {
            
            let destURL = documentsURL.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(atPath: destURL.path)
                }
                    
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
//                try FileManager.default.replaceItemAt(destURL, withItemAt: sourceURL)
                
                pLog.info("copied database \(fileName) (\(destURL.path)")
                
            } catch {
                pLog.debug("unable to save file \(fileName) to documents: err: \(error.localizedDescription)")
            }
        } else {
            pLog.debug("unable to save file \(fileName) to documents")
        }
    }
    
    func decode<T: Decodable>(_ type: T.Type, from file: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        let decoder = Data.sharedJSONDecoder

        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(file) from bundle due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(_) {
            fatalError("Failed to decode \(file) from bundle because it appears to be invalid JSON")
        } catch {
            fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
    }
}
