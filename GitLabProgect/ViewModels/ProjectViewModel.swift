import Combine
import Foundation

class ProjectViewModel: ObservableObject {

    private let projectsService: any ProjectsServicing
    private var cancellables = Set<AnyCancellable>()

    @Published var projects: [ProjectModel] = []
    @Published var isLoading = false

    init(projectsService: any ProjectsServicing = ProjectsService()) {
        self.projectsService = projectsService
    }

    func loadProjects() {
        isLoading = true

        projectsService.getProjects(page: 0, pageSize: 16)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("Error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.isLoading = false
                    self?.projects = data
                }
            )
            .store(in: &cancellables)
    }
}
