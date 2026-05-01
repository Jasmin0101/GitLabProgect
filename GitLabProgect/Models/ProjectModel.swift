//
//  File.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Foundation




struct ProjectModel: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let avatarUrl: URL? // В JSON: "avatar_url"
    let starCount: Int?  // В JSON: "star_count"
    let owner: OwnerModel?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case avatarUrl = "avatar_url"
        case starCount = "star_count"
        case owner
    }
}

extension ProjectModel {
    static let mockOwner = OwnerModel(
        id: 3,
        name: "Diaspora",

    )
    
    static let mock = ProjectModel(
        id: 101,
        name: "Diaspora Project Site",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        avatarUrl: URL(string: "http://example.com/uploads/project/avatar/3/uploads/avatar.png"),
        starCount: 125,
        owner: mockOwner
    )
    
    static let mockArray = [
        mock,
        ProjectModel(
            id: 102,
            name: "PINN-Research",
            description: "Solving math physics equations with PINN and NTK analysis.",
            avatarUrl: URL(string: "https://example.com/science.png"),
            starCount: 50,
            owner: OwnerModel(id: 4, name: "Jasmina",)
        )
    ]
}
