//
//  File.swift
//  
//
//  Created by blaine on 3/4/22.
//

import Foundation


// TODO: create hooks for custom backend methods
// TODO: create convience methods for request
// TODO: configuration loading [url, device_id, user_id]

internal struct AEBLEAPI {
    static func createExperiment(exp: Experiment) async -> Result<Bool, Error> {
        do {
            var req = URLRequest(url: URL(string: "http://159.223.153.215:80/experiment")!)
            
            let payload = ExperimentPayload(from: exp, deviceId: "test", userId: "test")
            
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            
            req.httpBody = try Data.sharedJSONEncoder.encode(payload)
            req.httpMethod = "POST"
            
            let (_, res) = try await URLSession.shared.data(for: req)
            guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                return .failure(
                    AEBLEError.aebleAPIHTTPError(
                        code: (res as! HTTPURLResponse).statusCode,
                        msg: "failure to create experiment"
                    )
                )
            }
            
            return .success(true)
        } catch {
            return .failure(AEBLEError.aebleAPIHTTPError(code: 0, msg: "unable to create experiment"))
        }
    }
    
    static func createTimestamp(ts: Timestamp) async -> Result<Bool, Error> {
        do {
            var req = URLRequest(url: URL(string: "http://159.223.153.215:80/timestamp")!)
            
            let payload = TimestampPayload(from: ts, deviceId: "test", userId: "test")
            
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            
            req.httpBody = try Data.sharedJSONEncoder.encode(payload)
            req.httpMethod = "POST"
            
            let (_, res) = try await URLSession.shared.data(for: req)
            guard (res as? HTTPURLResponse)?.statusCode == 200 else {
                return .failure(
                    AEBLEError.aebleAPIHTTPError(
                        code: (res as! HTTPURLResponse).statusCode,
                        msg: "failure to create experiment"
                    )
                )
            }
            
            return .success(true)
        } catch {
            return .failure(error)
        }
        
    }
    
    static func batchLoad(metadata: PeripheralCharacteristicMetadata, rows: [GenericRow]) async -> Result<Bool, Error> {
        do {
            var req = URLRequest(url: URL(string: "http://159.223.153.215:80/sensorData")!)
            
            let payload = SensorBatchPayload(
                deviceId: "test",
                userId: "test",
                metadata: metadata,
                values: rows.map({SensorBatchValue.from(row: $0, with: metadata)})
            )
            
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.httpMethod = "POST"
            
            req.httpBody = try Data.sharedJSONEncoder.encode(payload)
            
            let (_, res) = try await URLSession.shared.data(for: req)
            let urlRes = res as? HTTPURLResponse
            guard urlRes?.statusCode == 200 else {
                return .failure(
                    AEBLEError.aebleAPIHTTPError(
                        code: urlRes?.statusCode ?? 0,
                        msg: urlRes?.description ?? ""
                    )
                )
            }
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
}
