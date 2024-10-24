//
//  FXB+Collection.swift
//  
//
//  Created by Blaine Rothrock on 1/25/23.
//

import Foundation

extension Collection {
    subscript(optional i: Index) -> Element? {
        return indices.contains(i) ? self[i] : nil
    }
}
