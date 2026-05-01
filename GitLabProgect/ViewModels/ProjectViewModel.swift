import Combine
//
//  ProjectViewModel.swift
//  GitLabProgect
//
//  Created by Жасмина on 30.04.2026.
//
import Foundation

class ProjectViewModel: ObservableObject {

    private let projectsService: ProjectsService = ProjectsService()
    private var cacelables = Set<AnyCancellable>()

    @Published var projects: [ProjectModel] = []
    @Published var isLoading = false

    func loadProjects() {
        isLoading = true

        projectsService.getProjects(page: 0).receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    default:
                        break
                    }
                },
                receiveValue: {
                    [weak self] data in
                    
                    print("Data: \(data)")
                    self?.isLoading = false
                    self?.projects.append(contentsOf: data)
                }
            ).store(in: &cacelables)

    }
}
