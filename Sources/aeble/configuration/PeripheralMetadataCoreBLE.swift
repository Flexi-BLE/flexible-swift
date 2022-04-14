//
//  PeripheralMetadataCoreBLE.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import CoreBluetooth

internal extension AEThing {
    var serviceIds: [CBUUID] {
        return [CBUUID(string: "0x962a"), CBUUID(string: "0xcf3d"), CBUUID(string: "0x38ae")]
    }
    
    func serviceMetadata(by uuid: CBUUID) -> AEDataStream? {
        return self.dataStreams.first(where: { $0.cbuuid == uuid })
    }
}

internal extension AEDataStream {
    var cbuuid: CBUUID {
        return CBUUID(string: self.id)
    }
}

internal extension AEThing {
    var characteristicIds: [CBUUID] {
        return self.dataStreams.map({ ds -> CBUUID in
            return ds.cbuuid
        })
    }
    
    func characteristicMatadata(by uuid: CBUUID) -> AEDataStream? {
        return self.dataStreams.first(where: ({ $0.cbuuid == uuid }))
    }
}
