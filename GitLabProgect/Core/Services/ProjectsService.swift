import Combine
import Foundation

// Перечисление для обработки специфических ошибок сетевого слоя
enum ProjectsServiceError: Error {
    case invalidRequest              // Ошибка при создании URL
    case invalidResponse(statusCode: Int) // Ошибка, если сервер вернул плохой статус (например, 404 или 500)
}

// Протокол, описывающий возможности сервиса (удобно для тестирования и архитектуры)
protocol ProjectsServicing {
    func getProjects(page: Int, pageSize: Int, query: String?, orderByStarCount: Bool) -> AnyPublisher<[ProjectModel], Error>
}

final class ProjectsService: ProjectsServicing {
    private let session: URLSession // Объект сессии для выполнения сетевых запросов

    // Инициализатор с дефолтной общей сессией
    init(session: URLSession = .shared) {
        self.session = session
    }

    // Вспомогательная функция для сборки URLRequest
    private func makeRequest(
        page: Int,
        pageSize: Int,
        query: String?,
        orderByStarCount: Bool,
        includeAuthorization: Bool
    ) throws -> URLRequest {
        var components = URLComponents() // Конструктор URL
        components.scheme = "https"
        components.host = "gitlab.com"
        components.path = "/api/v4/projects"

        // Используем Result Builder для чистого формирования параметров запроса
        @ArrayBuilder<URLQueryItem>
        var queryItems: [URLQueryItem] {
            URLQueryItem(name: "page", value: "\(page)")
            URLQueryItem(name: "per_page", value: "\(pageSize)")
            
            // Если передан текст поиска, добавляем его в параметры
            if let query = query, !query.isEmpty {
                URLQueryItem(name: "search", value: query)
            }
            
            // Если нужна сортировка по звездам, добавляем соответствующие ключи API
            if orderByStarCount {
                URLQueryItem(name: "order_by", value: "star_count")
                URLQueryItem(name: "sort", value: "desc")
            }
        }

        components.queryItems = queryItems // Назначаем собранные параметры в URL

        // Пытаемся получить готовый URL, иначе выбрасываем ошибку
        guard let url = components.url else {
            throw ProjectsServiceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Указываем метод запроса
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Если флаг авторизации включен и токен существует, добавляем заголовок
        if includeAuthorization, let token = GitLabTokenProvider.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // Общая функция для выполнения запроса и парсинга JSON
    private func execute(_ request: URLRequest) -> AnyPublisher<[ProjectModel], Error> {
        let decoder = JSONDecoder()

        return session.dataTaskPublisher(for: request) // Создаем издателя для сетевого запроса
            .tryMap { data, response in
                // Проверяем, что ответ — это HTTP ответ
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ProjectsServiceError.invalidResponse(statusCode: -1)
                }

                // Проверяем статус-код (должен быть 200-299)
                guard 200...299 ~= httpResponse.statusCode else {
                    throw ProjectsServiceError.invalidResponse(statusCode: httpResponse.statusCode)
                }

                return data // Передаем сырые данные дальше по цепочке
            }
            .decode(type: [ProjectModel].self, decoder: decoder) // Пытаемся превратить JSON в массив моделей
            .mapError { $0 as Error } // Приводим возможные ошибки декодинга к общему типу Error
            .eraseToAnyPublisher()    // Скрываем сложный тип Combine за AnyPublisher
    }

    // Основной публичный метод для получения проектов
    func getProjects(
        page: Int,
        pageSize: Int = 16,
        query: String? = nil,
        orderByStarCount: Bool = false
    ) -> AnyPublisher<[ProjectModel], Error> {
        
        let authorizedRequest: URLRequest

        // 1. Пытаемся создать запрос с авторизацией
        do {
            authorizedRequest = try makeRequest(
                page: page,
                pageSize: pageSize,
                query: query,
                orderByStarCount: orderByStarCount,
                includeAuthorization: true
            )
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        // 2. Выполняем запрос
        return execute(authorizedRequest)
            .catch { [weak self] error -> AnyPublisher<[ProjectModel], Error> in
                // 3. Если получили ошибку 401 (не авторизован) или 403 (запрещено),
                // пробуем выполнить тот же запрос, но уже БЕЗ токена (для публичных проектов)
                guard
                    let self,
                    case ProjectsServiceError.invalidResponse(let statusCode) = error,
                    (statusCode == 401 || statusCode == 403),
                    authorizedRequest.value(forHTTPHeaderField: "Authorization") != nil
                else {
                    // Если ошибка другая или токена и так не было — просто пробрасываем ошибку дальше
                    return Fail(error: error).eraseToAnyPublisher()
                }

                do {
                    // Создаем "чистый" запрос без авторизации (fallback)
                    let fallbackRequest = try self.makeRequest(
                        page: page,
                        pageSize: pageSize,
                        query: query,
                        orderByStarCount: orderByStarCount,
                        includeAuthorization: false
                    )
                    return self.execute(fallbackRequest)
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
