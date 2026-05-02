import Combine
import Foundation

// ViewModel для управления логикой списка проектов
class ProjectViewModel: ObservableObject {

    // Сервис для работы с API (используем протокол для гибкости)
    private let projectsService: any ProjectsServicing
    // Набор для хранения подписок Combine, чтобы они не удалялись из памяти
    private var cancellables = Set<AnyCancellable>()

    // Наблюдаемые свойства: при их изменении SwiftUI автоматически перерисует экран
    @Published var projects: [ProjectModel] = []  // Массив загруженных проектов
    @Published var isLoading = false  // Индикатор процесса загрузки

    private var currentPage = 1
    private var canLoadMore = true
    // Инициализация с возможностью подмены сервиса (Dependency Injection)
    init(projectsService: any ProjectsServicing = ProjectsService()) {
        self.projectsService = projectsService
    }

    /// Загрузка проектов с поддержкой поиска и сортировки
    /// - Parameters:
    ///   - query: Строка поиска (необязательно)
    ///   - isPopular: Флаг сортировки по звездам (по умолчанию false)

    func loadProjects(
        query: String? = nil,
        isPopular: Bool = false,
        pageSize: Int,
        isFirstPage: Bool = false
    ) {

        guard !isLoading && (canLoadMore || isFirstPage) else { return }

        if isFirstPage {
            currentPage = 1
            projects = []
            canLoadMore = true
        }

        // Устанавливаем флаг загрузки в true, чтобы показать Spinner в UI
        isLoading = true

        // Вызываем метод сервиса с новыми параметрами
        projectsService.getProjects(
            page: currentPage,
            pageSize: pageSize,
            query: query,
            orderByStarCount: isPopular,
        )
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
                guard let self = self else { return }

                if isFirstPage {
                    self.projects = data
                } else {
                    // Избегаем дубликатов, если onAppear сработал дважды
                                    let newEntries = data.filter { newProj in
                                        !self.projects.contains(where: { $0.id == newProj.id })
                                    }
                                    self.projects.append(contentsOf: newEntries)
                }
                self.canLoadMore = data.count >= pageSize

                if !data.isEmpty {
                    self.currentPage += 1
                }
            }
        )
        // Сохраняем подписку в Set
        .store(in: &cancellables)
    }
}
