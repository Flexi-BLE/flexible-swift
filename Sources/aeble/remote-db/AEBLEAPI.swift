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

//internal struct AEBLEAPI {
//    static func createExperiment(
//        exp: Experiment,
//        settings: Settings
//    ) async -> Result<Bool, Error> {
//        
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/experiments")!)
//            
//            let payload = ExperimentPayload(
//                from: exp,
//                deviceId: settings.deviceId,
//                userId: settings.userId
//            )
//            
//            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            req.setValue("application/json", forHTTPHeaderField: "Accept")
//            
//            req.httpBody = try Data.sharedJSONEncoder.encode(payload)
//            req.httpMethod = "POST"
//            
//            let (_, res) = try await URLSession.shared.data(for: req)
//            guard (res as? HTTPURLResponse)?.statusCode == 200 else {
//                return .failure(
//                    AEBLEError.aebleAPIHTTPError(
//                        code: (res as! HTTPURLResponse).statusCode,
//                        msg: "failure to create experiment"
//                    )
//                )
//            }
//            
//            return .success(true)
//        } catch {
//            return .failure(AEBLEError.aebleAPIHTTPError(code: 0, msg: "unable to create experiment"))
//        }
//    }
//    
//    static func createTimestamp(
//        ts: Timestamp,
//        settings: Settings
//    ) async -> Result<Bool, Error> {
//        
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/timestamps")!)
//            
//            let payload = TimestampPayload(
//                from: ts,
//                deviceId: settings.deviceId,
//                userId: settings.userId
//            )
//            
//            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            req.setValue("application/json", forHTTPHeaderField: "Accept")
//            
//            req.httpBody = try Data.sharedJSONEncoder.encode(payload)
//            req.httpMethod = "POST"
//            
//            let (_, res) = try await URLSession.shared.data(for: req)
//            guard (res as? HTTPURLResponse)?.statusCode == 200 else {
//                return .failure(
//                    AEBLEError.aebleAPIHTTPError(
//                        code: (res as! HTTPURLResponse).statusCode,
//                        msg: "failure to create experiment"
//                    )
//                )
//            }
//            
//            return .success(true)
//        } catch {
//            return .failure(error)
//        }
//        
//    }
//    
//    static func batchLoad(
//        metadata: AEDataStream,
//        rows: [GenericRow],
//        settings: Settings
//    ) async -> Result<Bool, Error> {
//        
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/sensor_data/async")!)
//            let config = URLSessionConfiguration.background(withIdentifier: "com.\(metadata.name)")
//            let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
//            
//            let payload = SensorBatchPayload(
//                deviceId: settings.deviceId,
//                userId: settings.userId,
//                bucket: settings.sensorDataBucketName,
//                metadata: metadata,
//                values: rows.map({SensorBatchValue.from(row: $0, with: metadata)})
//            )
//            
//            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            req.setValue("application/json", forHTTPHeaderField: "Accept")
//            req.httpMethod = "POST"
//            
//            let data = try Data.sharedJSONEncoder.encode(payload)
//            
//            let tempDir = FileManager.default.temporaryDirectory
//            let localURL = tempDir.appendingPathComponent("throwaway")
//            try data.write(to: localURL)
//            
//            let task = session.uploadTask(with: req, fromFile: localURL)
//            task.resume()
//            
//            return .success(true)
//
////            let urlRes = res as? HTTPURLResponse
////            guard urlRes?.statusCode == 200 else {
////                return .failure(
////                    AEBLEError.aebleAPIHTTPError(
////                        code: urlRes?.statusCode ?? 0,
////                        msg: urlRes?.description ?? ""
////                    )
////                )
////            }
////            return .success(true)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//    static func getConfig(settings: Settings) async -> Result<AEDeviceConfig?, Error> {
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/device_configurations?id=\(settings.peripheralConfigurationId)")!)
//            req.httpMethod = "GET"
//            
//            let (data, res) = try await URLSession.shared.data(for: req)
//            let urlRes = res as? HTTPURLResponse
//            guard urlRes?.statusCode == 200 else {
//                return .failure(
//                    AEBLEError.aebleAPIHTTPError(
//                        code: urlRes?.statusCode ?? 0,
//                        msg: urlRes?.description ?? ""
//                    )
//                )
//            }
//            let config = try Data.sharedJSONDecoder.decode(AEDeviceConfig.self, from: data)
//            return .success(config)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//    static func getAvaiableConfigs(settings: Settings) async -> Result<[String], Error> {
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/device_configurations/available")!)
//            req.httpMethod = "GET"
//            
//            let (data, res) = try await URLSession.shared.data(for: req)
//            let urlRes = res as? HTTPURLResponse
//            guard urlRes?.statusCode == 200 else {
//                return .failure(
//                    AEBLEError.aebleAPIHTTPError(
//                        code: urlRes?.statusCode ?? 0,
//                        msg: urlRes?.description ?? ""
//                    )
//                )
//            }
//            let responsePayload = try Data.sharedJSONDecoder.decode(StringDataPayload.self, from: data)
//            return .success(responsePayload.data)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//    static func getBuckets(settings: Settings) async -> Result<[String], Error> {
//        do {
//            var req = URLRequest(url: URL(string: "\(settings.apiURL)/timeseries/buckets")!)
//            req.httpMethod = "GET"
//            
//            let (data, res) = try await URLSession.shared.data(for: req)
//            let urlRes = res as? HTTPURLResponse
//            guard urlRes?.statusCode == 200 else {
//                return .failure(
//                    AEBLEError.aebleAPIHTTPError(
//                        code: urlRes?.statusCode ?? 0,
//                        msg: urlRes?.description ?? ""
//                    )
//                )
//            }
//            let responsePayload = try Data.sharedJSONDecoder.decode(StringDataPayload.self, from: data)
//            return .success(responsePayload.data)
//        } catch {
//            return .failure(error)
//        }
//    }
//}
