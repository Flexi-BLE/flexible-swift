//
//  FXB+Collection.swift
//  
//
//  Created by Blaine Rothrock on 1/25/23.
//

import Foundation

extension Collection {
    subscript(optional index: Self.Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
