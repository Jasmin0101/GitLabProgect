import Combine
import Foundation

// ViewModel для управления логикой списка проектов
class ProjectViewModel: ObservableObject {

    // Сервис для работы с API (используем протокол для гибкости)
    private let projectsService: any ProjectsServicing
    // Набор для хранения подписок Combine, чтобы они не удалялись из памяти
    private var cancellables = Set<AnyCancellable>()

    // Наблюдаемые свойства: при их изменении SwiftUI автоматически перерисует экран
    @Published var projects: [ProjectModel] = [] // Массив загруженных проектов
    @Published var isLoading = false             // Индикатор процесса загрузки
    @Published var searchText = ""               // Текст поиска (можно связать с SearchBar)

    // Инициализация с возможностью подмены сервиса (Dependency Injection)
    init(projectsService: any ProjectsServicing = ProjectsService()) {
        self.projectsService = projectsService
    }

    /// Загрузка проектов с поддержкой поиска и сортировки
    /// - Parameters:
    ///   - query: Строка поиска (необязательно)
    ///   - isPopular: Флаг сортировки по звездам (по умолчанию false)
    func loadProjects(query: String? = nil, isPopular: Bool = false) {
        // Устанавливаем флаг загрузки в true, чтобы показать Spinner в UI
        isLoading = true

        // Вызываем метод сервиса с новыми параметрами
        projectsService.getProjects(page: 0, pageSize: 16, query: query, orderByStarCount: isPopular)
            // Переключаемся на главный поток, так как обновление UI должно происходить в нем
            .receive(on: DispatchQueue.main)
            // Подписываемся на результат (завершение или получение данных)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // В любом случае выключаем индикатор загрузки
                    self?.isLoading = false
                    
                    // Если произошла ошибка, выводим её в консоль
                    if case .failure(let error) = completion {
                        print("Error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    // При успешном получении данных обновляем наш массив проектов
                    self?.projects = data
                }
            )
            // Сохраняем подписку в Set
            .store(in: &cancellables)
    }
}
