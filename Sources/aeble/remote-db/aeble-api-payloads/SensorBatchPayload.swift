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
    let metadata: AEDataStream
    let values: [SensorBatchValue]
}

struct SensorBatchValue: Encodable {
    let time: Date
    let fieldNames: [String]
    let dataTypes: [AEDataValueType]
    let values: [String]

    
    static func from(row: GenericRow, with metadata: AEDataStream) -> SensorBatchValue {
        
        var time: Date = Date.now
        var fieldNames: [String] = []
        var dataTypes: [AEDataValueType] = []
        var values: [String] = []
        
        let dynamicDataValues: [String:AEDataValueDefinition] = metadata.dataValues.reduce(Dictionary<String, AEDataValueDefinition>(), { dict, dv in
            var dict = dict
            dict[dv.name] = dv
            return dict
        })
        
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
                dataTypes.append(.int)
                values.append("\(row.columns[i].value as! Int64)")
                // TODO: add alternative data type support
                
                fieldNames.append(dv.name)
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
