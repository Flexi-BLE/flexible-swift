//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 12/27/22.
//

import Foundation
@testable import flexiBLE_Core

enum SpecMock {
    
    static var valid: FXBSpecification {
        guard let url = Bundle.module.url(forResource: "valid_spec", withExtension: "json") else {
            fatalError("unable to find valid specification mock JSON")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let spec = try SpecCoding.Decoder.decode(FXBSpecification.self, from: data)
            return spec
        } catch {
            fatalError("unable to decode specification")
        }
    }
}
