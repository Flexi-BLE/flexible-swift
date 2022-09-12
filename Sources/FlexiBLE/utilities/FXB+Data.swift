//
//  FXB+Data.swift
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
        decoder.dateDecodingStrategy = .formatted(Data.sharedISODateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return decoder
    }
    
    static var sharedJSONEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Data.sharedISODateFormatter)
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return encoder
    }
    
    static var sharedISODateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return df
    }
}
