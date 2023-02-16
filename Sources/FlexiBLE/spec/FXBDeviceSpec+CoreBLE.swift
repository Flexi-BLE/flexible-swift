//
//  PeripheralMetadataCoreBLE.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import CoreBluetoothMock

internal extension FXBDeviceSpec {
    var serviceIds: [CBUUID] {
        let serviceIds = self.dataStreams.map({ $0.serviceCbuuid })
        let registeredId = self.bleRegisteredServices.map({ $0.uuid })
        return serviceIds + registeredId + [CBUUID.FlexiBLEServiceUUID]
    }
    
    func charMetadata(by uuid: CBUUID) -> FXBDataStream? {
        return self.dataStreams.first(where: { [$0.dataCbuuid, $0.configCbuuid].contains(uuid) })
    }
    
    var dataStreamcharacteristicIds: [CBUUID] {
        var uuids = [CBUUID]()
        
        for ds in self.dataStreams {
            uuids.append(CBUUID(string: ds.ble.configCharUuid))
            uuids.append(CBUUID(string: ds.ble.dataCharUuid))
        }
        
        return uuids
    }
    
    func dataStreams(from uuid: CBUUID) -> [FXBDataStream] {
        return self.dataStreams
            .filter({ $0.serviceCbuuid == uuid })
    }
}

internal extension FXBDataStream {
    var dataCbuuid: CBUUID {
        return CBUUID(string: self.ble.dataCharUuid)
    }
    
    var configCbuuid: CBUUID {
        return CBUUID(string: self.ble.configCharUuid)
    }
    
    var serviceCbuuid: CBUUID {
        return CBUUID(string: self.ble.serviceUuid)
    }
}

internal extension FXBRegisteredDeviceSpec {
    var serviceIds: [CBUUID] {
        return self.services.map({ $0.uuid })
    }
}
