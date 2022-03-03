//
//  Data.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation

internal extension Data {
    /// simple hex encoding
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Shared
    static var sharedJSONDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return decoder
    }
    
    static var sharedJSONEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return encoder
    }
    
    static var sharedISODateDecoder: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.S Z"
        return df
    }
}
