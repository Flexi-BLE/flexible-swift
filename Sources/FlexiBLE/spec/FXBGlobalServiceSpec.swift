//
//  FXBGlobalServiceSpec.swift
//  
//
//  Created by Blaine Rothrock on 3/8/23.
//

import Foundation

public class FXBGlobalServiceSpec: Codable {
    public let configValues: [FXBDataStreamConfig]
    public let commands: [FXBCommandSpec]
}
