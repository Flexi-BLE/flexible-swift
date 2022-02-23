//
//  File.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation

/// Representation of a time frame
internal struct Event: Codable {
    var id: Int64?
    var name: String
    var start: Date
    var end: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case start
        case end
    }
}
