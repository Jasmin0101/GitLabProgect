//
//  File.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Foundation

struct ProjectStatistics: Codable , Hashable , Equatable {
    let repositorySize: Int?
    let commitCount: Int?

    enum CodingKeys: String, CodingKey {
        case repositorySize = "repository_size"
        case commitCount = "commit_count"
    }
}

struct ProjectModel: Identifiable, Codable , Hashable , Equatable {
    let id: Int
    let name: String
    let description: String?
    let avatarUrl: URL? // В JSON: "avatar_url"
    let starCount: Int?  // В JSON: "star_count"
    let forksCount: Int? // В JSON: "forks_count"
    let lastActivityAt: String? // В JSON: "last_activity_at"
    let webUrl: URL? // В JSON: "web_url"
    let topics: [String]?
    let statistics: ProjectStatistics?
    let owner: OwnerModel?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case avatarUrl = "avatar_url"
        case starCount = "star_count"
        case forksCount = "forks_count"
        case lastActivityAt = "last_activity_at"
        case webUrl = "web_url"
        case topics
        case statistics
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
        forksCount: 37,
        lastActivityAt: "2026-04-30T16:20:00.000Z",
        webUrl: URL(string: "https://gitlab.com/example/diaspora"),
        topics: ["social", "swiftui", "api"],
        statistics: ProjectStatistics(repositorySize: 1_038_090, commitCount: 874),
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
            forksCount: 14,
            lastActivityAt: "2026-04-28T09:00:00.000Z",
            webUrl: URL(string: "https://gitlab.com/example/pinn-research"),
            topics: ["research", "ml"],
            statistics: ProjectStatistics(repositorySize: 523_000, commitCount: 37),
            owner: OwnerModel(id: 4, name: "Jasmina",)
        )
    ]
}
