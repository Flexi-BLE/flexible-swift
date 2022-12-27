//
//  SpecCoding.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

enum SpecCoding {
    /// Holds static objects for help in decoding and encoding spec JSON files
    
    static var Decoder: JSONDecoder {
        /// Global JSONDecoder for FlexiBLE Specification files
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(SpecCoding.ISODateFormatter)
        return decoder
    }
    
    static var Encoder: JSONEncoder {
        /// Global JSONEncoder for FlexiBLE Specification files
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(SpecCoding.ISODateFormatter)
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
    static var ISODateFormatter: DateFormatter {
        /// Global date formatter for millisecond precision (ISO-8601)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return df
    }
}
