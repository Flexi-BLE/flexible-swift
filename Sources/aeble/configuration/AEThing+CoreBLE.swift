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
    
    func charMetadata(by uuid: CBUUID) -> AEDataStream? {
        return self.dataStreams.first(where: { [$0.notifyCbuuid, $0.dataCbuuid, $0.timeOffsetCbuuid].contains(uuid) })
    }
    
    var timeSyncCbuuid: CBUUID {
        return CBUUID(string: timestampSync.id)
    }
    
    var infoCharacteristicIds: [CBUUID] {
        return [timeSyncCbuuid]
    }
    
    var dataStreamcharacteristicIds: [CBUUID] {
        var uuids = [CBUUID]()
        
        for ds in self.dataStreams {
            uuids.append(CBUUID(string: ds.ble.notifyId))
            uuids.append(CBUUID(string: ds.ble.dataId))
            uuids.append(CBUUID(string: ds.ble.timeOffsetId))
        }
        
        return uuids
    }
}

internal extension AEDataStream {
    var notifyCbuuid: CBUUID {
        return CBUUID(string: self.ble.notifyId)
    }

    var dataCbuuid: CBUUID {
        return CBUUID(string: self.ble.dataId)
    }
    
    var timeOffsetCbuuid: CBUUID {
        return CBUUID(string: self.ble.timeOffsetId)
    }
}
