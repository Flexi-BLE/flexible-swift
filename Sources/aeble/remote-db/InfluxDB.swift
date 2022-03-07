//
//  InfluxDB.swift
//  
//
//  Created by blaine on 3/3/22.
//

import Combine
import Foundation
import InfluxDBSwift

// TODO: REMOVE

struct InfluxDB {
    static func makeClient() -> InfluxDBClient {
        let options = InfluxDBClient.InfluxDBOptions(
            bucket: "ntrain-dump",
            org: "kamoamoa",
            precision: .ns,
            enableGzip: true
        )

        let client = InfluxDBClient(
            url: "http://159.223.153.215:8086",
            token: "beBDnoDquyaCRAIYe7Zj77TsrAH76NQ83KIclK156IiSSPCNncE8nNSmkzHnOY5zo7DXp7rTI32iLEwOD_W9HA==",
            options: options
        )

        return client
    }

    static func writePoints(_ points: [InfluxDBClient.Point]) -> Result<Bool, Error> {
        let client = InfluxDB.makeClient()
        
        var res: Result<Bool, Error> = .failure(AEBLEError.influxError(msg: "unable to insert record"))
        
        client.makeWriteAPI().write(points: points) { result, error in
            defer { client.close() }

            if let error = error {
                res = .failure(error)
            }

            if result != nil {
                res = .success(true)
            }
        }
        
        return res
    }
    
    static func writeEventStart(exp: Experiment) -> Result<Bool, Error> {
        let p = InfluxDBClient.Point("experiment")
            .addTag(key: "type", value: "start")
            .addTag(key: "name", value: exp.name)
            .addTag(key: "uuid", value: exp.uuid)
            .time(time: .date(exp.start))
        
        return InfluxDB.writePoints([p])
    }
    
    static func writeEventEnd(exp: Experiment) -> Result<Bool, Error> {
        guard let end = exp.end else {
            return .failure(AEBLEError.influxError(msg: "no enddate provided"))
        }
        
        let p = InfluxDBClient.Point("experiment")
            .addTag(key: "type", value: "end")
            .addField(key: "name", value: .string(exp.name))
            .addField(key: "uuid", value: .string(exp.uuid))
            .addField(key: "ext", value: .int(1))
            .time(time: .date(end))
        
        return InfluxDB.writePoints([p])
    }
    
    static func writeTimestamp(ts: Timestamp) -> Result<Bool, Error> {
        let p = InfluxDBClient.Point("timestamp")
            .addField(key: "name", value: .string(ts.name ?? "--none--"))
            .addField(key: "description", value: .string(ts.description ?? "--none--"))
            .addField(key: "experimentId", value: .int(Int(ts.experimentId ?? -1)))
            .addField(key: "ext", value: .int(1))
            .time(time: .date(ts.datetime))
        
        return InfluxDB.writePoints([p])
    }
    
    static func writeGenericRows(rows: [GenericRow],
                                 name: String,
                                 metadata: PeripheralCharacteristicMetadata) -> Result<Bool, Error> {
            
            
        var ps = [InfluxDBClient.Point]()
        let dynamicDataValues: [String:PeripheralMetadataDataValue] = metadata.dataValues?.reduce(Dictionary<String, PeripheralMetadataDataValue>(), { dict, dv in
            var dict = dict
            dict[dv.name] = dv
            return dict
        }) ?? [:]
            
        for row in rows {
            
            let p = InfluxDBClient.Point(name)
            
            for i in 0..<row.columns.count {
                let rowName = row.metadata[i].name
                if rowName == "created_at" {
                    var dstring = row.columns[i].value as! String
                    dstring += " UTC"
                    let d = Data.sharedISODateDecoder.date(from: dstring)!
                    p.time(time: .date(d))
                }
                
                if let dv = dynamicDataValues[rowName] {
                    switch dv.type {
                    case .float: p.addField(key: dv.name, value: .double(row.columns[i].value as! Double))
                    case .int: p.addField(key: dv.name, value: .int(row.columns[i].value as! Int))
                    case .string: p.addField(key: dv.name, value: .string(row.columns[i].value as! String))
                    }
                }
                
            }
            
            // TODO: add device and user id
                        
            ps.append(p)
        }
        
        return InfluxDB.writePoints(ps)
    }
}
