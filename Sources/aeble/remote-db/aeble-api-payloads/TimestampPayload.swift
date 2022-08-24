//
//  File.swift
//  
//
//  Created by blaine on 3/4/22.
//

import Foundation


internal struct TimestampPayload: Codable {
    let deviceId: String
    let userId: String
    let name: String?
    let description: String?
    let time: Date
    
    init(from ts: Timestamp, deviceId: String, userId: String) {
        self.deviceId = deviceId
        self.userId = userId
        self.name = ts.name
        self.description = ts.description
        self.time = ts.datetime
    }
}
