//
//  UIDevice.swift
//  
//
//  Created by blaine on 2/23/22.
//

import Foundation
import UIKit

internal extension UIDevice {
    var Id: String {
        return self.identifierForVendor?.uuidString ?? "--none--"
    }
}
