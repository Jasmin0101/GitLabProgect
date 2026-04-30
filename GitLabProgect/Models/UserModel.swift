//
//  UserModel.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import SwiftUI
import Foundation
//Identifiable - показатель уникальности ?
import Foundation

struct UserModel: Identifiable, Codable {
    let id: Int
    let username: String     // В JSON: "username"
    var name: String         // В JSON: "name"
    var avatarUrl: URL?      // В JSON: "avatar_url"
    var webUrl: URL?         // В JSON: "web_url"
    var bio: String?         // В JSON: "bio"
    var location: String?    // В JSON: "location"
    var publicEmail: String? // В JSON: "public_email"

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case name
        case avatarUrl = "avatar_url"
        case webUrl = "web_url"
        case bio
        case location
        case publicEmail = "public_email"
    }
}

extension UserModel {
    static let mock = UserModel(
        id: 1,
        username: "jasmina_dev",
        name: "Жасмина Избосарова",
        avatarUrl: URL(string: "https://example.com/avatar1.jpg"),
        webUrl: URL(string: "https://gitlab.example.com/jasmina_dev"),
        bio: "iOS Developer | ML Research",
        location: "Vladivostok",
        publicEmail: "jasmina@fefu.ru"
    )
    
    static let mockArray = [
        mock,
        UserModel(
            id: 2,
            username: "john_smith",
            name: "John Smith",
            avatarUrl: nil,
            webUrl: URL(string: "https://gitlab.example.com/john_smith"),
            bio: "GitLab Admin",
            location: nil,
            publicEmail: "john@example.com"
        ),
        UserModel(
            id: 3,
            username: "swift_pro",
            name: "Alice Smith",
            avatarUrl: URL(string: "https://example.com/avatar2.jpg"),
            webUrl: URL(string: "https://gitlab.example.com/swift_pro"),
            bio: nil,
            location: "Berlin",
            publicEmail: nil
        )
    ]
}
