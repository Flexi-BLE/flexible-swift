//
//  FXBCommandSpec.swift
//  
//
//  Created by Blaine Rothrock on 3/8/23.
//

import Foundation

internal enum FXBCommandHeader: UInt8 {
    case request = 0
    case response = 1
}

public class FXBCommandSpec: Codable {
    public var commandCode: UInt8
    public var appRequests: [FXBCommandSpecRequest]
//    var deviceRequests: [FXBCommandSpecRequest]
}

public class FXBCommandSpecRequest: Codable {
    public let code: UInt8
    public let name: String
    public let responses: [FXBCommandSpecResponse]
    public let description: String
}

public enum FXBCommandSpecResponseType: String, Codable {
    case success
    case error
}

public class FXBCommandSpecResponse: Codable {
    public let code: UInt8
    public let description: String
    public let responseType: FXBCommandSpecResponseType
}
