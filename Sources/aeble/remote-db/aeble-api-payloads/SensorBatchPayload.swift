//
//  SensorBatchPayload.swift
//  
//
//  Created by blaine on 3/7/22.
//

import Foundation


struct SensorBatchPayload: Encodable {
    let deviceId: String
    let userId: String
    let bucket: String
    let metadata: PeripheralCharacteristicMetadata
    let values: [SensorBatchValue]
}

struct SensorBatchValue: Encodable {
    let time: Date
    let fieldNames: [String]
    let dataTypes: [PeripheralMetadataDataValueType]
    let values: [String]

    
    static func from(row: GenericRow, with metadata: PeripheralCharacteristicMetadata) -> SensorBatchValue {
        
        var time: Date = Date.now
        var fieldNames: [String] = []
        var dataTypes: [PeripheralMetadataDataValueType] = []
        var values: [String] = []
        
        let dynamicDataValues: [String:PeripheralMetadataDataValue] = metadata.dataValues?.reduce(Dictionary<String, PeripheralMetadataDataValue>(), { dict, dv in
            var dict = dict
            dict[dv.name] = dv
            return dict
        }) ?? [:]
        
        for i in 0..<row.columns.count {
            let rowName = row.metadata[i].name
            if rowName == "created_at" {
                var dstring = row.columns[i].value as! String
                // TODO: helper for SQLite -> ISO8601 w/ millseconds
                dstring = dstring.replacingOccurrences(of: " ", with: "T")
                dstring += "Z"
                time = Data.sharedISODateFormatter.date(from: dstring)!
            }
            
            if let dv = dynamicDataValues[rowName] {
                dataTypes.append(dv.type)
                fieldNames.append(dv.name)
                switch dv.type {
                case .float:
                    values.append("\(row.columns[i].value as! Double)")
                case .int:
                    values.append("\(row.columns[i].value as! Int)")
                case .string:
                    values.append("\(row.columns[i].value as! Double)")
                }
            }
        }
        
        return SensorBatchValue(
            time: time,
            fieldNames: fieldNames,
            dataTypes: dataTypes,
            values: values
        )
    }
}
