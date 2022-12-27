//
//  FXBSpecAuthor.swift
//  
//
//  Created by Blaine Rothrock on 12/20/22.
//

import Foundation

public class FXBSpecAuthor: Codable {
    let name, organization, email: String
    
    init(name: String, organization: String, email: String) {
        self.name = name
        self.organization = organization
        self.email = email
    }
}
