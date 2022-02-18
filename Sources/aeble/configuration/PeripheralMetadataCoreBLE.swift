//
//  PeripheralMetadataCoreBLE.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import CoreBluetooth

internal extension PeripheralMetadata {
    var serviceIds: [CBUUID] {
        return self.services?.map({ sm -> CBUUID in
            return sm.cbuuid
        }) ?? []
    }
    
    func serviceMetadata(by uuid: CBUUID) -> PeripheralServiceMetadata? {
        return self.services?.first(where: { $0.cbuuid == uuid })
    }
}

internal extension PeripheralCharacteristicMetadata {
    var cbuuid: CBUUID {
        return CBUUID(string: self.uuid)
    }
}

internal extension PeripheralServiceMetadata {
    var cbuuid: CBUUID {
        return CBUUID(string: self.uuid)
    }
    
    var characteristicIds: [CBUUID] {
        return self.characteristics?.map({ cm -> CBUUID in
            return cm.cbuuid
        }) ?? []
    }
    
    func characteristicMatadata(by uuid: CBUUID) -> PeripheralCharacteristicMetadata? {
        return self.characteristics?.first(where: ({ $0.cbuuid == uuid }))
    }
}
