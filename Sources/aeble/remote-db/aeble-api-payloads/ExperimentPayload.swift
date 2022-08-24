//
//  ExperimentPayload.swift
//  
//
//  Created by blaine on 3/4/22.
//

import Foundation


internal struct ExperimentPayload: Codable {
    let deviceId: String
    let userId: String
    let name: String
    let description: String?
    let startTime: Date
    let endTime: Date
    
    init(from exp: Experiment, deviceId: String, userId: String) {
        self.deviceId = deviceId
        self.userId = userId
        self.name = exp.name
        self.description = exp.description
        self.startTime = exp.start
        self.endTime = exp.end ?? Date.now
    }
}
