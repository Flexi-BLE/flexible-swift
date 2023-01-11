//
//  FXBRemoteDatabaseUploader.swift
//  
//
//  Created by blaine on 9/1/22.
//

import Foundation
import Combine
import GRDB


public enum FXBDataUploaderState {
    case notStarted
    case initializing
    case running
    case paused
    case error(msg: String)
    case done
    
    public var rawValue: Int {
        switch self {
        case .notStarted: return 0
        case .initializing: return 1
        case .running: return 2
        case .paused: return 3
        case .error(msg: _): return 4
        case .done: return 5
        }
    }
    
    public var stringValue: String {
        switch self {
        case .notStarted: return "not started"
        case .initializing: return "initializing"
        case .running: return "running"
        case .paused: return "paused"
        case .error(let msg): return "error: \(msg)"
        case .done: return "done"
        }
    }
    
    public static func ==(lhs:FXBDataUploaderState, rhs:FXBDataUploaderState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public protocol FXBRemoteDatabaseUploader {
    var state: FXBDataUploaderState { get }
    var progress: Float { get }
    var estNumRecs: Int { get }
    var totalUploaded: Int { get }
    var tableUploaders: [FXBTableUploader] { get }
    var statusMessage: String { get }
    
    
    func upload() async -> Result<Bool, Error>
    func pause()
}
