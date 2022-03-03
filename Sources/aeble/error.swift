//
//  File.swift
//  
//
//  Created by blaine on 2/24/22.
//

import Foundation


public enum AEBLEError: Error {
    case dbError(msg: String)
    case influxError(msg: String)
}
