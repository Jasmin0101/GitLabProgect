//
//  LanguageViewModel.swift
//  GitLabProgect
//
//  Created by Жасмина on 01.05.2026.
//

import Combine
import Foundation

class LanguageViewModel: ObservableObject {

    private let languageService:  LanguageService
    private var cancellables = Set<AnyCancellable>()

    // Словарь, где ключ — название языка, а значение — процент (Double)
    @Published var languages: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init(languageService:  LanguageService = LanguageService()) {
        self.languageService = languageService
    }

    func loadLanguages(for projectId: Int) {
        isLoading = true
        errorMessage = nil

        languageService.getLanguage(id: projectId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("Error loading languages: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    // data здесь — это [String: Double]
                    self?.languages = data
                }
            )
            .store(in: &cancellables)
    }
}
