import Combine
import Foundation

// ViewModel для управления логикой списка проектов
class ProjectViewModel: ObservableObject {

    // Сервис для работы с API (используем протокол для гибкости)
    private let projectsService: any ProjectsServicing
    // Набор для хранения подписок Combine, чтобы они не удалялись из памяти
    private var cancellables = Set<AnyCancellable>()
    private let starredProjectsStorageKey = "starred_project_ids"

    // Наблюдаемые свойства: при их изменении SwiftUI автоматически перерисует экран
    @Published var projects: [ProjectModel] = []  // Массив загруженных проектов
    @Published var isLoading = false  // Индикатор процесса загрузки
    @Published private(set) var starredProjectIDs: Set<Int> = []
    @Published private(set) var projectDetailsByID: [Int: ProjectModel] = [:]
    @Published private(set) var detailLoadingIDs: Set<Int> = []
    @Published private(set) var detailErrorByID: [Int: String] = [:]

    private var currentPage = 1
    private var canLoadMore = true
    private var activeQueryForPagination: String? = nil

    // RU -> EN раскладка клавиатуры (йцукен -> qwerty)
    private let ruToEnKeyboardMap: [Character: Character] = [
        "й": "q", "ц": "w", "у": "e", "к": "r", "е": "t", "н": "y", "г": "u", "ш": "i", "щ": "o", "з": "p",
        "х": "[", "ъ": "]", "ф": "a", "ы": "s", "в": "d", "а": "f", "п": "g", "р": "h", "о": "j", "л": "k",
        "д": "l", "ж": ";", "э": "'", "я": "z", "ч": "x", "с": "c", "м": "v", "и": "b", "т": "n", "ь": "m",
        "б": ",", "ю": ".", ".": "/"
    ]

    // Инициализация с возможностью подмены сервиса (Dependency Injection)
    init(projectsService: any ProjectsServicing = ProjectsService()) {
        self.projectsService = projectsService

        let savedIDs = UserDefaults.standard.array(forKey: starredProjectsStorageKey) as? [Int] ?? []
        self.starredProjectIDs = Set(savedIDs)
    }

    // MARK: - Stars

    func isStarred(projectID: Int) -> Bool {
        starredProjectIDs.contains(projectID)
    }

    func toggleStar(for projectID: Int) {
        if starredProjectIDs.contains(projectID) {
            starredProjectIDs.remove(projectID)
        } else {
            starredProjectIDs.insert(projectID)
        }
        persistStarredProjects()
    }

    func displayedStarCount(for project: ProjectModel) -> Int {
        let base = max(0, project.starCount ?? 0)
        return base + (isStarred(projectID: project.id) ? 1 : 0)
    }

    // MARK: - Project Details

    func projectDetails(for projectID: Int) -> ProjectModel? {
        projectDetailsByID[projectID]
    }

    func isDetailLoading(for projectID: Int) -> Bool {
        detailLoadingIDs.contains(projectID)
    }

    func detailError(for projectID: Int) -> String? {
        detailErrorByID[projectID]
    }

    func loadProjectDetails(projectID: Int, forceRefresh: Bool = false) {
        if !forceRefresh, projectDetailsByID[projectID] != nil {
            return
        }

        guard !detailLoadingIDs.contains(projectID) else { return }

        detailLoadingIDs.insert(projectID)
        detailErrorByID[projectID] = nil

        projectsService.getProjectDetails(projectID: projectID)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.detailLoadingIDs.remove(projectID)

                    if case .failure(let error) = completion {
                        self.detailErrorByID[projectID] = error.localizedDescription
                        print("Detail error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] detailProject in
                    guard let self = self else { return }
                    self.projectDetailsByID[projectID] = detailProject
                    self.detailErrorByID[projectID] = nil

                    if let index = self.projects.firstIndex(where: { $0.id == projectID }) {
                        self.projects[index] = detailProject
                    }
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Ranking

    /// Возвращает проекты, отсортированные по релевантности и популярности.
    func rankedProjects(for query: String) -> [ProjectModel] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return projects.sorted {
                let lhsStars = displayedStarCount(for: $0)
                let rhsStars = displayedStarCount(for: $1)
                if lhsStars == rhsStars {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return lhsStars > rhsStars
            }
        }

        let candidates = searchCandidates(for: trimmedQuery)

        return projects.sorted { lhs, rhs in
            let lhsScore = score(for: lhs, queryCandidates: candidates)
            let rhsScore = score(for: rhs, queryCandidates: candidates)

            if lhsScore == rhsScore {
                let lhsStars = displayedStarCount(for: lhs)
                let rhsStars = displayedStarCount(for: rhs)
                if lhsStars == rhsStars {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsStars > rhsStars
            }

            return lhsScore > rhsScore
        }
    }

    private func score(
        for project: ProjectModel,
        queryCandidates: [String]
    ) -> Double {
        let name = project.name.lowercased()
        let description = (project.description ?? "").lowercased()

        let similarityScore = queryCandidates
            .map { candidate in
                scoreSimilarity(
                    name: name,
                    description: description,
                    query: candidate
                )
            }
            .max() ?? 0.0

        // Логарифм сглаживает разницу между очень большими и средними проектами
        let stars = max(0, displayedStarCount(for: project))
        let popularityScore = min(1.0, log10(Double(stars) + 1) / 5.0)

        return (similarityScore * 0.75) + (popularityScore * 0.25)
    }

    private func scoreSimilarity(
        name: String,
        description: String,
        query: String
    ) -> Double {
        var similarityScore = 0.0

        if name == query {
            similarityScore += 1.0
        }
        if name.hasPrefix(query) {
            similarityScore += 0.8
        }
        if name.contains(query) {
            similarityScore += 0.55
        }
        if description.contains(query) {
            similarityScore += 0.3
        }

        let queryTokens = query
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        for token in queryTokens where token.count > 1 {
            if name.contains(token) {
                similarityScore += 0.14
            }
            if description.contains(token) {
                similarityScore += 0.06
            }
        }

        return similarityScore
    }

    // MARK: - Data loading

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
        loadProjects(
            query: query,
            isPopular: isPopular,
            pageSize: pageSize,
            isFirstPage: isFirstPage,
            didTryAlternativeQuery: false
        )
    }

    private func loadProjects(
        query: String?,
        isPopular: Bool,
        pageSize: Int,
        isFirstPage: Bool,
        didTryAlternativeQuery: Bool
    ) {

        guard (isFirstPage || !isLoading) && (canLoadMore || isFirstPage) else { return }

        if isFirstPage {
            currentPage = 1
            projects = []
            canLoadMore = true
            activeQueryForPagination = nil

            // Отменяем предыдущие запросы, чтобы старый ответ не перезаписал новый поиск
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
        }

        // Устанавливаем флаг загрузки в true, чтобы показать Spinner в UI
        isLoading = true

        let normalizedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        let incomingQueryValue = (normalizedQuery?.isEmpty == false) ? normalizedQuery : nil
        let queryValue = isFirstPage ? incomingQueryValue : activeQueryForPagination

        if isFirstPage {
            activeQueryForPagination = queryValue
        }

        // Вызываем метод сервиса с новыми параметрами
        projectsService.getProjects(
            page: currentPage,
            pageSize: pageSize,
            query: queryValue,
            orderByStarCount: isPopular
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

                if isFirstPage,
                   data.isEmpty,
                   !didTryAlternativeQuery,
                   let alternativeQuery = self.alternativeQueryIfNeeded(from: queryValue),
                   !alternativeQuery.isEmpty {
                    self.isLoading = false
                    self.loadProjects(
                        query: alternativeQuery,
                        isPopular: isPopular,
                        pageSize: pageSize,
                        isFirstPage: true,
                        didTryAlternativeQuery: true
                    )
                    return
                }

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

    private func searchCandidates(for query: String) -> [String] {
        let normalized = query.lowercased()
        var result: [String] = [normalized]

        if let alternative = alternativeQueryIfNeeded(from: normalized), alternative != normalized {
            result.append(alternative)
        }

        return result
    }

    private func alternativeQueryIfNeeded(from query: String?) -> String? {
        guard let query,
              !query.isEmpty,
              query.rangeOfCharacter(from: .whitespacesAndNewlines.inverted) != nil
        else {
            return nil
        }

        let lowered = query.lowercased()
        let hasCyrillic = lowered.range(of: "[\\u0400-\\u04FF]", options: .regularExpression) != nil
        let hasLatin = lowered.range(of: "[a-z]", options: .regularExpression) != nil

        // Альтернатива нужна только если строка набрана в одной раскладке.
        if hasCyrillic && !hasLatin {
            let mapped = convertKeyboardLayout(lowered, using: ruToEnKeyboardMap)
            return mapped == lowered ? nil : mapped
        }

        if hasLatin && !hasCyrillic {
            let enToRuMap = Dictionary(uniqueKeysWithValues: ruToEnKeyboardMap.map { ($0.value, $0.key) })
            let mapped = convertKeyboardLayout(lowered, using: enToRuMap)
            return mapped == lowered ? nil : mapped
        }

        return nil
    }

    private func convertKeyboardLayout(_ text: String, using map: [Character: Character]) -> String {
        String(text.map { map[$0] ?? $0 })
    }

    private func persistStarredProjects() {
        UserDefaults.standard.set(Array(starredProjectIDs), forKey: starredProjectsStorageKey)
    }
}
