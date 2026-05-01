//
//  ProjectsService.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Combine
import Foundation

enum ProjectsServiceError: Error {
    case invalidRequest
    case invalidResponse
}

protocol ProjectsServicing {
    func getProjects(page: Int, pageSize: Int) -> AnyPublisher<[ProjectModel], Error>
}

final class ProjectsService: ProjectsServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func makeRequest(page: Int, pageSize: Int) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "gitlab.com"
        components.path = "/api/v4/projects"

        @ArrayBuilder<URLQueryItem>
        var queryItems: [URLQueryItem] {
            URLQueryItem(name: "page", value: "\(page)")
            URLQueryItem(name: "per_page", value: "\(pageSize)")
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw ProjectsServiceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Public projects can be loaded without token.
        // If token exists, we add authorization to expand access.
        if let token = GitLabTokenProvider.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func getProjects(page: Int, pageSize: Int = 16) -> AnyPublisher<[ProjectModel], Error> {
        let request: URLRequest
        do {
            request = try makeRequest(page: page, pageSize: pageSize)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let decoder = JSONDecoder()

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode
                else {
                    throw ProjectsServiceError.invalidResponse
                }
                return data
            }
            .decode(type: [ProjectModel].self, decoder: decoder)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
