//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import OSLog

/// General Logging
let gLog = Logger(subsystem: "com.hesterlab.aeble", category: "general")

/// Bluetooth Logging
let bleLog = Logger(subsystem: "com.hesterlab.aeble", category: "ble")

/// Persistence (Data) Logging
let pLog = Logger(subsystem: "com.hesterlab.aeble", category: "persistence")
