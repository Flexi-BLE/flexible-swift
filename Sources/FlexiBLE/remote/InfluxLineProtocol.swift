//
//  InfluxLineProtocol.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation

internal class ILPRecord {
    let staticTable: FXBTimeSeriesTable
    let recordId: Int64
    
    let measurement: String
    let timestamp: Date
    
    var tags: [String:String] = [:]
    var fields: [String:String] = [:]
    
    init(staticTable: FXBTimeSeriesTable, id: Int64, measurement: String, timestamp: Date) {
        self.staticTable = staticTable
        self.recordId = id
        self.measurement = measurement
        self.timestamp = timestamp
    }
    
    func tag(_ name: String, _ val: String) {
        tags[name] = "\(val)"
    }
    
    func field(_ name: String, float: Float) {
        fields[name] = "\(float)"
    }
    
    func field(_ name: String, int: Int) {
        fields[name] = "\(int)i"
    }
    
    func field(_ name: String, uint: UInt) {
        fields[name] = "\(uint)u"
    }
    
    func field(_ name: String, str: String) {
        fields[name] = "\"\(str)\""
    }
    
    var line: String {
        var s = "\(measurement)"
        
        if !tags.isEmpty {
            for (name, tag) in tags {
                s += ",\(name)=\(tag)"
            }
        }
        
        if !fields.isEmpty {
            for (i, (name, value)) in fields.enumerated() {
                if i == 0 {
                    s += " "
                } else {
                    s += ","
                }
                
                s += "\(name)=\(value)"
            }
        }
        
        s += " \(timestamp.unixEpochNanoseconds)"
        
        return s
    }
}

extension Array where Element == ILPRecord {
    func ship(url baseURL: URL, org: String, bucket: String, token: String) async throws -> Bool {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "org", value: org),
            URLQueryItem(name: "bucket", value: bucket)
        ]
        guard let url = urlComponents?.url else {
            return false
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = self.map({ $0.line }).joined(separator: "\n").data(using: .utf8)
        
        guard self.count > 0 else {
            return true
        }
        
        webLog.debug("uploading records, sample: \(self[0].line)")
        
        let (data, res) = try await URLSession.shared.data(for: req)

        guard let httpRes = res as? HTTPURLResponse else {
            return false
        }
        if (200...299).contains(httpRes.statusCode) {
            webLog.info("successful influx upload for \(self.first?.measurement ?? "--unknown--"), count: \(self.count): \(httpRes.statusCode)")
            return true
        } else {
            webLog.error("error: \(String(data: data, encoding: .utf8) ?? "--unknown--")")
        }

        return false
    }
}
