//
//  ApiService.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//

import Foundation

enum ApiServiceError: Error {
    case invalidURL
        case noData
        case decodingError
}


final class ApiService{
    
//    Это создание того самого Синглтона.
//    
//    static — свойство принадлежит самому типу, а не конкретному объекту.
//
//    Мы создаем его один раз и обращаемся к нему так:
    
    static let shared = ApiService()
        
    private init(){}
    
    private let token = ""
    private let baseURL = "https://gitlab.com/api/v4"
    
    // Swift: (Result<[ProjectModel], Error>) -> Void
    // Dart: Future<void> Function(Result<List<ProjectModel>, Exception>)
//    GET /projects/:id
//    curl --request GET \
//    --header "PRIVATE-TOKEN: <your_access_token>" \
//    --url "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
    
    func fetchProjects(completion: @escaping (Result<[ProjectModel], Error> )  -> Void , perPage: Int = 20 ) {
        
            // 1. Создаем URL (например, список твоих проектов)
        
            guard let url = URL(string: "\(baseURL)/projects?pagination\(perPage)") else {
                completion(.failure(ApiServiceError.invalidURL))
                return
            }

            // 2. Создаем запрос и добавляем заголовок авторизации
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // 3. Отправляем запрос
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(ApiServiceError.noData))
                    return
                }

                // 4. Декодируем JSON в наши модели
                do {
                    let decoder = JSONDecoder()
                    // Настраиваем декодер под формат GitLab (snake_case не нужен, если есть CodingKeys)
                    let projects = try decoder.decode([ProjectModel].self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(.success(projects))
                    }
                } catch {
                    print("Decoding error: \(error)")
                    completion(.failure(ApiServiceError.decodingError))
                }
            }.resume()
        }
    
}
