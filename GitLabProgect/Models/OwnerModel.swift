//
//  OwnerModel.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Foundation


struct OwnerModel: Codable, Identifiable , Hashable , Equatable {
    let id: Int
    let name: String

    
    enum CodingKeys: String, CodingKey {
        case id
        case name

    }
}
