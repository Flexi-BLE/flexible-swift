//
//  File.swift
//  
//
//  Created by Blaine Rothrock on 2/15/23.
//

import Foundation
import CoreBluetoothMock
@testable import FlexiBLE

enum TestUtils {
    internal static func tearDownFlexiBLE() throws {
        try FlexiBLEAppData.shared.deleteAppData()
    }
}
