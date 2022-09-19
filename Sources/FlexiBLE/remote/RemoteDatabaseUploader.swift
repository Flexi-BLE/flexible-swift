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

//public protocol FXBRemoteDatabaseUploader: ObservableObject {
//    var state: FXBDataUploaderState { get }
//    var stateValue: Published<FXBDataUploaderState> { get }
//    var statePublisher: Published<FXBDataUploaderState>.Publisher { get }
//
//    var progress: Float { get }
//    var progressValue: Published<Float> { get }
//    var progressPublisher: Published<Float>.Publisher { get }
//
//    var estNumRecs: Int { get }
//    var estNumRecsValue: Published<Int> { get }
//    var estNumRecsPublisher: Published<Int>.Publisher { get }
//
//    var totalUploaded: Int { get }
//    var totalUploadedValue: Published<Int> { get }
//    var totalUploadedPublisher: Published<Int>.Publisher { get }
//
//    var batchSize: Int { get }
//    var tableStatuses: [FXBTableUploadState] { get }
//
//
//    func start()
//    func pause()
//}

public protocol FXBRemoteDatabaseUploader {
    var state: FXBDataUploaderState { get }
    var progress: Float { get }
    var estNumRecs: Int { get }
    var totalUploaded: Int { get }
    var batchSize: Int { get }
    var tableStatuses: [FXBTableUploadState] { get }
    
    
    func start()
    func pause()
}

public class FXBTableUploadState {
    var table: FXBTimeSeriesTable
    var startDate: Date?
    var endDate: Date?
    var totalRemaining: Int
    var uploaded: Int
    
    init(table: FXBTimeSeriesTable) {
        self.table = table
        self.startDate = nil
        self.endDate = nil
        self.totalRemaining = 0
        self.uploaded = 0
    }
}
