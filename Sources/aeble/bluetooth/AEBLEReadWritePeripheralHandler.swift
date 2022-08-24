//
//  File.swift
//  
//
//  Created by blaine on 7/15/22.
//

import Foundation


// Previous implementation of Peripheral Delegate copying for safe keeping

//public enum AEBLEPeripheralState: String {
//    case notFound = "not found"
//    case connected = "connected"
//    case disconnected = "disconnected"
//}
//
///// AEBLE Bluetooth Enabled CoreBluetooth Delegate
/////
///// - Author: Blaine Rothrock
//public class AEBLEPeripheral: NSObject, ObservableObject {
//    @Published public private(set) var state: AEBLEPeripheralState = .disconnected
//
//    var isEnabled: Bool = true
//
//    /// AE Representation of Peripheral
//    public let metadata: AEThing
//
//    @Published public var batteryLevel: Int?
//
//    private var uploaders: [AEStreamDataUploader] = []
//
//    /// Reference to database
//    /// - Remark:
//    ///  Holding reference to the database is not ideal, this should be reworked to require database dependency.
//    private let db: AEBLEDBManager
//
//    /// typealias to hold stateful collection of data stream characteristic reads
//    private typealias DataStreamPacket = (timestamp: UInt64?, dataPayload: Data?, timePayload: Data?)
//
//    /// Stores temporary state of individual data stream read
//    private var dataStreamPackets: [CBUUID:DataStreamPacket] = [:]
//
//    /// Keeps track of each timestamp associated with each data steam read to avoid duplicate reads
//    private var epochReadIdentifiers: [CBUUID: UInt64] = [:]
//
//    /// Core Bluetooth Peripheral
//    internal var cbp: CBPeripheral?
//
//    @Published public var rssi: Int = 0
//
//    init(metadata: AEThing, db: AEBLEDBManager) {
//        self.metadata = metadata
//        self.db = db
//    }
//
//    func set(peripheral: CBPeripheral) {
//        self.cbp = peripheral
//        self.didUpdateState()
//    }
//
//    func didUpdateState() {
//        guard let peripheral = self.cbp else { return }
//
//        switch peripheral.state {
//        case .connected, .connecting: self.onConnect()
//        default: self.onDisconnect()
//        }
//    }
//
//    public func requestRSSI() {
//        cbp?.readRSSI()
//    }
//
//    private func onConnect() {
//        guard let peripheral = self.cbp else { return }
//        self.state = .connected
//        peripheral.delegate = self
//
//        peripheral.discoverServices(metadata.serviceIds)
//    }
//
//    private func onDisconnect() {
//        self.state = .disconnected
//    }
//}
//
//// MARK: - Core Bluetooth Peripheral Delegate
//extension AEBLEPeripheral: CBPeripheralDelegate {
//    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//
//        for service in services {
//            print(service)
//            if service.uuid == CBUUID(string: metadata.ble.dataServiceId) {
//                let charIds = metadata.dataStreamcharacteristicIds
//                peripheral.discoverCharacteristics(charIds, for: service)
//            } else if service.uuid == CBUUID(string: metadata.ble.infoServiceId) {
//                peripheral.discoverCharacteristics(metadata.infoCharacteristicIds, for: service)
//            } else if service.uuid == CBUUID(string: metadata.ble.configServiceId) {
//                // TODO: discover configuration services
//            } else if let _ = BLERegisteredService.from(service.uuid) {
//                bleLog.debug("did discovery registered service")
//                peripheral.discoverCharacteristics(nil, for: service)
//            }
//        }
//    }
//
//    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        bleLog.info("did discover characteristics for \(service.uuid)")
//
//        guard let characteristics = service.characteristics else {
//            bleLog.error("no characteristics found for \(service.uuid)")
//            return
//        }
//
//        bleLog.info("found \(characteristics.count) characteristics for service \(service.uuid)")
//
//        if service.uuid == CBUUID(string: metadata.ble.dataServiceId) {
//            setupCharsDataService(
//                peripheral: peripheral,
//                characteristics: characteristics
//            )
//        }
//
//        if service.uuid == CBUUID(string: metadata.ble.infoServiceId) {
//            setupCharsInfoService(peripheral: peripheral, characteristics: characteristics)
//        }
//
//        if service.uuid == CBUUID(string: metadata.ble.configServiceId) {
//            // TODO: setup configuration service
//        }
//
//        if let _ = BLERegisteredService.from(service.uuid)  {
//            handleRegisteredServiceDiscovery(peripheral: peripheral, service: service)
//        }
//    }
//
//    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        bleLog.info("did update value for characteristic \(characteristic.uuid)")
//
//        if let error = error {
//            bleLog.error("BLE Update Error: \(error.localizedDescription)")
//            return
//        }
//
//        if let md = metadata.charMetadata(by: characteristic.uuid) {
//            handleDataSteamCharUpdate(
//                peripheral: peripheral,
//                characteristic: characteristic,
//                md: md
//            )
//        }
//
//        if characteristic.uuid == metadata.timeSyncCbuuid {
//            handleTimeSync(peripheral: peripheral, characteristic: characteristic)
//        }
//
//        if let service = characteristic.service,
//           let _ = BLERegisteredService.from(service.uuid)  {
//            handleRegisteredServiceUpdate(peripheral: peripheral, char: characteristic)
//        }
//    }
//
//    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
//        self.rssi = Int(truncating: RSSI)
//    }
//}
//
//// MARK: - Core Bluetooth Delegate Helpers
//extension AEBLEPeripheral {
//
//    /// set notify values for info characteristics
//    private func setupCharsInfoService(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) {
//        for chr in characteristics {
//            if chr.uuid == metadata.timeSyncCbuuid {
//                peripheral.setNotifyValue(true, for: chr)
//                bleLog.info("notifying for time sync characteristic")
//            }
//        }
//    }
//
//    /// set notify values for data (data stream) characteristics
//    private func setupCharsDataService(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) {
//        for chr in characteristics {
//            bleLog.info("characteristic: \(chr.uuid): \(chr.properties.rawValue)")
//
//            if let md = metadata.charMetadata(by: chr.uuid) {
//                if chr.uuid == md.notifyCbuuid {
//                    peripheral.setNotifyValue(true, for: chr)
//                }
//                db.createTable(from: md, forceNew: false)
//                peripheral.readValue(for: chr)
//            }
//        }
//    }
//
//    /// write current epoch time (milliseconds) AE device time sync info characteristics
//    private func handleTimeSync(
//        peripheral: CBPeripheral,
//        characteristic: CBCharacteristic
//    ) {
//
//        guard let data = characteristic.value else { return }
//
//        let val = data.withUnsafeBytes({ $0.load(as: UInt64.self) })
//        if val == 1 {
//            // requesting time sync
//            let ts: UInt64 = UInt64(Date.now.timeIntervalSince1970 * 1000.0)
//            bleLog.info("syncing time to \(ts)")
//            peripheral.writeValue(
//                withUnsafeBytes(of: ts, { Data($0) }),
//                for: characteristic,
//                type: .withoutResponse
//            )
//        }
//
//    }
//
//    /// manage statful collection of data stream characterisics
//    /// notify with epoch time, data, and time offsets
//    private func handleDataSteamCharUpdate(
//        peripheral: CBPeripheral,
//        characteristic: CBCharacteristic,
//        md: AEDataStream
//    ) {
//
//        guard let service = characteristic.service,
//                let data = characteristic.value else { return }
//
//        if characteristic.uuid == md.notifyCbuuid {
//            let notifyVal: UInt8 = data[0]
//            var ts: UInt64? = nil
//
//            // use epoch time as the unique identifier of the payload
//            var epochCheck = true
//            if md.includeAnchorTimestamp && data.count == 9 {
//                ts = Data(data[1..<9]).withUnsafeBytes({ $0.load(as: UInt64.self) })
//                bleLog.debug("extracting epoch time: \(ts ?? 0)")
//
//                epochCheck = ts != epochReadIdentifiers[md.notifyCbuuid]
//                epochReadIdentifiers[md.notifyCbuuid] = ts ?? 0
//            }
//
//            if notifyVal > 0, epochCheck {
//                // kick off data collection
//                bleLog.info("data stream notify value \(notifyVal) \(characteristic.uuid)")
//                dataStreamPackets[md.notifyCbuuid] = DataStreamPacket(ts, nil, nil)
//                if let dataChr = service
//                    .characteristics?
//                    .first(where: { $0.uuid == md.dataCbuuid }) {
//
//                    // read data (up to 512 bytes)
//                    peripheral.readValue(for: dataChr)
//                }
//                if md.includeOffsetTimestamp {
//                    if let toChr = service
//                        .characteristics?
//                        .first(where: { $0.uuid == md.timeOffsetCbuuid }) {
//
//                        // read time offsets
//                        peripheral.readValue(for: toChr)
//                    }
//                }
//            }
//        }
//
//        // handle data reads
//        if characteristic.uuid == md.dataCbuuid {
//            bleLog.info("recieved data of size \(data.count)")
//            if data.count > 0 {
//                dataStreamPackets[md.notifyCbuuid]?.dataPayload = data
//                if dspSatisfied(md: md) {
//                    processDataStreamPacket(
//                        peripheral: peripheral,
//                        service: service,
//                        md: md)
//                }
//            }
//        }
//
//        // hand time series offset reads
//        if characteristic.uuid == md.timeOffsetCbuuid {
//            bleLog.info("recieved time offset data of size \(data.count)")
//            if data.count > 0 {
//                dataStreamPackets[md.notifyCbuuid]?.timePayload = data
//                if dspSatisfied(md: md) {
//                    processDataStreamPacket(
//                        peripheral: peripheral,
//                        service: service,
//                        md: md)
//                }
//            }
//        }
//    }
//
//    // determine if all data has been collected from a data stream
//    private func dspSatisfied(md: AEDataStream) -> Bool {
//        guard let dsp = dataStreamPackets[md.notifyCbuuid] else { return false }
//        if let _ = dsp.dataPayload,
//            !md.includeOffsetTimestamp {
//            return true
//        }
//
//        if let _ = dsp.dataPayload,
//           let _ = dsp.timePayload {
//            return true
//        }
//
//        return false
//
//    }
//
//    private func processDataStreamPacket(peripheral: CBPeripheral, service: CBService, md: AEDataStream) {
//
//        guard let dsp = dataStreamPackets[md.notifyCbuuid] else { return }
//
//        bleLog.debug("processing data values")
//
//        var date = Date()
//
//
//        if let ts = dsp.timestamp {
//            let ti = TimeInterval(Double(ts) / 1000.0)
//            date = Date(timeIntervalSince1970: ti)
//            bleLog.debug("inferring epoch time \(ts):\(date)")
//        }
//
//        resetDataStreamNotify(peripheral: peripheral, service: service, uuid: md.notifyCbuuid)
//        // async task to extract values and insert into local database
//        Task(priority: .high) { [date] in await insertDataStream(db: db, packet: dsp, md: md, date: date) }
//    }
//
//    // reset count of data stream notification value when read
//    private func resetDataStreamNotify(peripheral:CBPeripheral, service: CBService, uuid: CBUUID) {
//        if let notifyChr = service
//            .characteristics?
//            .first(where: { $0.uuid == uuid }) {
//
//            peripheral.readValue(for: notifyChr)
//
//            peripheral.writeValue(Data([UInt8(0)]), for: notifyChr, type: .withoutResponse)
//        }
//    }
//
//    private func insertDataStream(db: AEBLEDBManager, packet: DataStreamPacket, md: AEDataStream, date: Date) async {
//        var dataValues: [AEDataValue] = []
//        var tsValues: [AEDataValue] = []
//
//        if let data = packet.dataPayload {
//            bleLog.debug("parsing data values")
//            dataValues = AEBLEPeripheral.parseData(data: data, dataValues: md.dataValues)
//        }
//
//        if let data = packet.timePayload {
//            bleLog.debug("parsing time offsets")
//            tsValues = AEBLEPeripheral.parseData(data: data, dataValues: [md.timeOffsetValue])
//        }
//
//        await db.arbInsert(
//            for: md,
//            dataValues: dataValues,
//            tsValues: tsValues,
//            date: date
//        )
//
//        if let uploader = uploaders.first(where: { $0.dataStream.name == md.name }) {
//            await uploader.check()
//        } else {
//            let uploader = AEStreamDataUploader(
//                db: db,
//                dataStream: md,
//                timeLimit: 120,
//                recordLimit: md.uploadBatchSize,
//                purgeAfter: 500
//            )
//            uploaders.append(uploader)
//            await uploader.check()
//        }
//    }
//
//    // extract and process reach record according to metadata specifications
//    private static func parseData(data: Data, dataValues: [AEDataValueDefinition]) -> [AEDataValue] {
//        // FIXME: assumes no time offsets
//
//        var cursor = 0
//
//        let readingSize = dataValues.reduce(0, { $0 + $1.size })
//
//        var values: [AEDataValue] = []
//
//        for _ in 0..<(data.count / readingSize) {
//            // must copy (new array) or we run into memory issues
//            let payload: [UInt8] = Array(data[cursor..<(cursor+readingSize)])
//
//            for dv in dataValues {
//                let bytes = payload[dv.byteStart..<dv.byteEnd]
//                var rawValue: Int = 0
//                for byte in bytes {
//                    rawValue = rawValue << 8
//                    rawValue = rawValue | Int(byte)
//                }
//
//                if dv.isSigned {
//                    // TODO: handle signed
//                }
//
//                if dv.isUnsignedNegative {
//                    // TODO: handle sign flipping
//                }
//
//                if dv.precision > 0 {
//                    // TODO: handle precision (double)
//                }
//
////                bleLog.debug("  - raw value extracted: \(rawValue)")
//                values.append(rawValue)
//            }
//
//            cursor += readingSize
//        }
//
//        return values
//    }
//}
//
//
//// MARK: - Registered Services
//extension AEBLEPeripheral {
//    func handleRegisteredServiceDiscovery(peripheral: CBPeripheral, service: CBService) {
//        switch BLERegisteredService.from(service.uuid) {
//        case .battery: setupBatteryLevel(peripheral: peripheral, service: service)
//        default: break
//        }
//    }
//
//
//    func setupBatteryLevel(peripheral: CBPeripheral, service: CBService) {
//        guard let batLevelChar = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "2a19") }) else { return }
//
//        peripheral.setNotifyValue(true, for: batLevelChar)
//
//        peripheral.readValue(for: batLevelChar)
//    }
//
//    func handleRegisteredServiceUpdate(peripheral: CBPeripheral, char: CBCharacteristic) {
//        guard let service = char.service else { return }
//        switch BLERegisteredService.from(service.uuid) {
//        case .battery: didUpdateBattery(char)
//        default: break
//        }
//    }
//
//    func didUpdateBattery(_ char: CBCharacteristic) {
//        guard let data = char.value else {
//            return
//        }
//        self.batteryLevel = Int(data[0])
//    }
//}
