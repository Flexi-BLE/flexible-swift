//
//  File.swift
//  
//
//  Created by blaine on 7/19/22.
//

import Foundation
import Combine

public class FXBConfigValue: ObservableObject {
    let def: FXBDataStreamConfig
    @Published var value: String
    
    var readableValue: String {
        if let options = def.options,
           let i = Int(value) {
            return options[optional: i]?.name ?? "--unknown--"
        }
        
        return value
    }
    
    init(def: FXBDataStreamConfig) {
        self.def = def
        value = def.defaultValue
    }
    
    func load(from data: Data) {
        switch def.dataType {
        case .float: break
        case .int:
            var val : Int = 0
            for byte in data {
                val = val << 8
                val = val | Int(byte)
            }

            value = String(value)
        case .unsignedInt:
            var val : UInt = 0
            for byte in data {
                val = val << 8
                val = val | UInt(byte)
            }
            
            value = String(Int(val))
        case .string:
            self.value = String(bytes: data[def.byteStart...def.byteEnd], encoding: .utf8) ?? "--unknown value--"
        }
        
        bleLog.debug("Loaded config value: \(self.value) from \(self.def.name)")
    }
}
