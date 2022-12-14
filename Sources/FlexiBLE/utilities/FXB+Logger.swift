//
//  FXB+Logger.swift
//  
//
//  Created by Blaine Rothrock on 2/17/22.
//

import Foundation
import OSLog

/// General Logging
internal let gLog = Logger(subsystem: "com.blainerothrock.flexible", category: "general")

/// Bluetooth Logging
internal let bleLog = Logger(subsystem: "com.blainerothrock.flexible", category: "ble")

/// Persistence (Data) Logging
internal let pLog = Logger(subsystem: "com.blainerothrock.flexible", category: "persistence")

/// Remote Upload Logger
internal let webLog = Logger(subsystem: "com.blainerothrock.flexible", category: "outbound-web")

/// temp developmental logging
internal let devLog = Logger(subsystem: "com.blainerothrock.flexible", category: "dev")
