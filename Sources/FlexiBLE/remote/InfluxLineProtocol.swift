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

enum InfluxDBUploadError: Error {
    case invalidURL
    case unknownHttpResult
    case httpError(statusCode: Int, message: String)
}

extension InfluxDBUploadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalild Influx URL"
        case .unknownHttpResult: return "Unable to parse HTTP response"
        case .httpError(let statusCode, let message):
            return "HTTP Error (\(statusCode)): \(message)"
        }
    }
}

extension Array where Element == ILPRecord {
    func ship(with credentials: InfluxDBCredentials) async -> Result<Bool, Error> {
        var urlComponents = URLComponents(url: credentials.url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "org", value: credentials.org),
            URLQueryItem(name: "bucket", value: credentials.bucket)
        ]
        guard let url = urlComponents?.url else {
            return .failure(InfluxDBUploadError.invalidURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Token \(credentials.token)", forHTTPHeaderField: "Authorization")
        req.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = self.map({ $0.line }).joined(separator: "\n").data(using: .utf8)
        
        guard self.count > 0 else {
            return .success(true)
        }
        
        webLog.debug("uploading records, sample: \(self[0].line)")
        
        do {
            let (data, res) = try await URLSession.shared.data(for: req)
            
            guard let httpRes = res as? HTTPURLResponse else {
                return .failure(InfluxDBUploadError.unknownHttpResult)
            }
            
            if (200...299).contains(httpRes.statusCode) {
                webLog.info("successful influx upload for \(self.first?.measurement ?? "--unknown--"), count: \(self.count): \(httpRes.statusCode)")
                return .success(true)
            } else {
                let responseMessage = String(data: data, encoding: .utf8) ?? "--unknown--"
                webLog.error("error: \(responseMessage)")
                return .failure(InfluxDBUploadError.httpError(statusCode: httpRes.statusCode, message: responseMessage))
            }
        } catch {
            return .failure(error)
        }

        
    }
}
