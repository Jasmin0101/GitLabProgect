//
//  LanguageService.swift
//  GitLabProgect
//
//  Created by Жасмина on 01.05.2026.
//

import Combine
import Foundation
//GET /projects/:id/languages
enum LanguageServiceError: Error {
    case invalidRequest
    case invalidResponse
}


final class LanguageService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func makeRequest(id: Int) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "gitlab.com"
        components.path = "/api/v4/projects/\(id)/languages"
      


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

    func getLanguage(id: Int) -> AnyPublisher<[String: Double], Error> {
        let request: URLRequest
        do {
            request = try makeRequest(id: id)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

   

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode
                else {
                    throw LanguageServiceError.invalidResponse
                }
                return data
            }
            .decode(type: [String: Double].self, decoder: JSONDecoder())
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
