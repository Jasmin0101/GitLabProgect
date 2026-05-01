//
//  ProjectsService.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Combine
import Foundation

final class ProjectsService {

    private let apiKey: String =
        "glpat-X9qg-ij08FlVJQaX3vpICmM6MQpvOjEKdTpna2N3bg8.01.171hfuzve"

    private func makeRequest(page: Int, pageSize: Int = 16) -> URLRequest? {
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

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        return request
    }

    func getProjects(page: Int, pageSize: Int = 16) -> AnyPublisher<
        [ProjectModel], any Error
    > {

        guard let request = makeRequest(page: page, pageSize: pageSize)
        else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // Магическая строка для исправления 90% ошибок
        
        let dataPublisher = URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                if let json = String(data: data, encoding: .utf8) {
                    print("API response:", json)
                }
            })
            .decode(type: [ProjectModel].self, decoder: decoder)
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ ОШИБКА: Ключ '\(key.stringValue)' не найден!")
                        print("📍 Путь: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        
                    case .valueNotFound(let type, let context):
                        print("❌ ОШИБКА: Значение типа \(type) не найдено (null там, где не ждали).")
                        print("📍 Путь: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        
                    case .typeMismatch(let type, let context):
                        print("❌ ОШИБКА: Несоответствие типов! Ожидался \(type).")
                        print("📍 Путь: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        
                    case .dataCorrupted(let context):
                        print("❌ ОШИБКА: Данные повреждены (невалидный JSON).")
                        print("📍 Контекст: \(context.debugDescription)")
                    @unknown default:
                        print("❌ Неизвестная ошибка декодирования.")
                    }
                }
                return error
            }
            .eraseToAnyPublisher()

        return dataPublisher

    }

}
