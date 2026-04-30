//
//  OwnerModel.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Foundation


struct OwnerModel: Codable, Identifiable {
    let id: Int
    let name: String
    let createdAt: String // В JSON: "created_at"
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}
