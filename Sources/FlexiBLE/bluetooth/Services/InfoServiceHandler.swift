//
//  AEInfoServiceHandler.swift
//  
//
//  Created by Blaine Rothrock on 7/21/22.
//

import Foundation
import CoreBluetooth
import Combine
import GRDB

public class InfoServiceHandler: ServiceHandler, ObservableObject {
    var serviceUuid: CBUUID

    private let spec: FXBDeviceSpec
    
    internal var referenceMs: UInt64?
    
    public enum InfoError: Error {
        case invalidReferenceId
        case noVersionId
        case noSpecId
    }
    
    public struct InfoData {
        public let referenceDate: Date
        public let specId: String
        public let versionId: String
    }

    @Published public var versionId: String? = nil
    @Published public var specId: String? = nil
    @Published public var referenceDate: Date? = nil
    public var infoPublisher = PassthroughSubject<InfoData, InfoError>()
    
    private var dataObserver: AnyCancellable?
    
    init(spec: FXBDeviceSpec) {
        self.spec = spec
        self.serviceUuid = spec.infoServiceUuid
        
        self.dataObserver = Publishers
            .Zip3($referenceDate, $versionId, $specId)
            .dropFirst() // ignore nil initilaization
            .sink { [weak self] refDate, versionId, specId in
                guard let refDate = refDate else {
                    self?.infoPublisher.send(completion: .failure(InfoError.invalidReferenceId))
                    return
                }
                
                guard let specId = specId else {
                    self?.infoPublisher.send(completion: .failure(InfoError.noSpecId))
                    return
                }
                
                guard let versionId = versionId else {
                    self?.infoPublisher.send(completion: .failure(InfoError.noVersionId))
                    return
                }
                
                self?.infoPublisher.send(
                    InfoData(
                        referenceDate: refDate,
                        specId: specId,
                        versionId: versionId
                    )
                )
            }
    }
    
    private func writeEpoch(peripheral: CBPeripheral, characteristic epochChar: CBCharacteristic) {
        let now = Date()
        var nowMs = UInt64(now.timeIntervalSince1970*1000)
        var data = Data()
        withUnsafePointer(to: &nowMs) {
            data.append(UnsafeBufferPointer(start: $0, count: 1))
        }
        
        bleLog.info("Writing epoch time to \(peripheral.name ?? "--device--"): \(now) (\(nowMs))")
        
        peripheral.writeValue(data, for: epochChar, type: .withResponse)
    
        self.referenceMs = nowMs
    }
    
    func setup(peripheral: CBPeripheral, service: CBService) {
        
        if let epochChar = service.characteristics?.first(where: { $0.uuid == spec.epochTimeUuid }) {
            writeEpoch(peripheral: peripheral, characteristic: epochChar)
        }
        
        // set notify for epoch reset request
        if let epochResetChar = service.characteristics?.first(where: { $0.uuid == spec.refreshEpochUuid }) {
            peripheral.setNotifyValue(true, for: epochResetChar)
        }
        
        if let versionChar = service.characteristics?.first(where: { $0.uuid == spec.specVersionUuid }) {
            peripheral.readValue(for: versionChar)
        }
        
        if let idChar = service.characteristics?.first(where: { $0.uuid == spec.specIdUuid }) {
            peripheral.readValue(for: idChar)
        }
    }
    
    func didWrite(uuid: CBUUID) {
        bleLog.debug("did write value for \(self.spec.name)")
    }
    
    func didUpdate(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
        
        if characteristic.uuid == spec.epochTimeUuid {
            
            if data.count == 8 {
            
                let refMs = data.withUnsafeBytes({ $0.load(as: UInt64.self) })
                if refMs != referenceMs {
                    bleLog.error("failed to update epoch time")
                    referenceDate = nil
                    referenceMs = nil
                } else {
                    self.referenceDate = Date(timeIntervalSince1970: Double(refMs)/1000.0)
                }
            }
            
            
        } else if characteristic.uuid == spec.specVersionUuid {
            let versionMajor = Int(data[0])
            let versionMinor = Int(data[1])
            let versionPatch = Int(data[2])
            let version = "\(versionMajor).\(versionMinor).\(versionPatch)"
            bleLog.info("specification version for \(self.spec.name): \(version)")
            self.versionId = version
            
        } else if characteristic.uuid == spec.specIdUuid {
            let id = String(data: data, encoding: .ascii)?.replacingOccurrences(of: "\0", with: "")
            bleLog.info("specification id for \(self.spec.name): \(id ?? "--none--")")
            self.specId = id
            
        } else if characteristic.uuid == spec.refreshEpochUuid {
            if data[0] == 1 {
                writeEpoch(peripheral: peripheral, characteristic: characteristic)
            }
        }
    }
}
