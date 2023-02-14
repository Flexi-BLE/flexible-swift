//
//  CBAdvertisementData.swift
//  
//
//  Created by Blaine Rothrock on 2/14/23.
//

import Foundation
import CoreBluetooth

public struct CBAdvertisementData {
    internal let data: [String : Any]
    
    public var id: UUID = UUID()
    
    public var name: String? {
        return data["kCBAdvDataLocalName"] as? String
    }
    
    var serviceIds: [CBUUID] {
        return data["kCBAdvDataServiceUUIDs"] as? [CBUUID] ?? []
    }
    
    public var isConnectable: Bool {
        return data["kCBAdvDataIsConnectable"] as? Bool ?? false
    }
    
    public var powerLevel: Int? {
        return data["CBAdvertisementDataTxPowerLevel"] as? Int
    }
    
    var solicitedServiceIds: [CBUUID] {
        return data["CBAdvertisementDataSolicitedServiceUUIDs"] as? [CBUUID] ?? []
    }
}
