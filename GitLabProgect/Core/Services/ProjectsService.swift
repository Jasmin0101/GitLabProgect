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
    case invalidResponse(statusCode: Int)
}

protocol ProjectsServicing {
    func getProjects(page: Int, pageSize: Int) -> AnyPublisher<[ProjectModel], Error>
}

final class ProjectsService: ProjectsServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func makeRequest(page: Int, pageSize: Int, includeAuthorization: Bool) throws -> URLRequest {
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

        if includeAuthorization, let token = GitLabTokenProvider.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute(_ request: URLRequest) -> AnyPublisher<[ProjectModel], Error> {
        let decoder = JSONDecoder()

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ProjectsServiceError.invalidResponse(statusCode: -1)
                }

                guard 200...299 ~= httpResponse.statusCode else {
                    throw ProjectsServiceError.invalidResponse(statusCode: httpResponse.statusCode)
                }

                return data
            }
            .decode(type: [ProjectModel].self, decoder: decoder)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getProjects(page: Int, pageSize: Int = 16) -> AnyPublisher<[ProjectModel], Error> {
        let authorizedRequest: URLRequest

        do {
            authorizedRequest = try makeRequest(page: page, pageSize: pageSize, includeAuthorization: true)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return execute(authorizedRequest)
            .catch { [weak self] error -> AnyPublisher<[ProjectModel], Error> in
                guard
                    let self,
                    case ProjectsServiceError.invalidResponse(let statusCode) = error,
                    (statusCode == 401 || statusCode == 403),
                    authorizedRequest.value(forHTTPHeaderField: "Authorization") != nil
                else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                do {
                    let fallbackRequest = try self.makeRequest(page: page, pageSize: pageSize, includeAuthorization: false)
                    return self.execute(fallbackRequest)
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
