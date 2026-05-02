//
//  HomeView.swift
//  GitLabProgect
//
//  Created by Жасмина on 29.04.2026.
//

import SwiftUI

struct HomeView: View {

    @StateObject var projetsViewModel: ProjectViewModel
    @StateObject var languageViewModel: LanguageViewModel

    @State private var previewProject: ProjectModel? = nil
    @State private var selectedProjectForNavigation: ProjectModel? = nil
    @State private var searchQuery = ""
    @State private var searchDebounceWorkItem: DispatchWorkItem?
    @Environment(\.colorScheme) private var colorScheme

    private let darkBackground = AppTheme.Palette.darkBackground
    private let pageSize = 20

    private var rankedProjects: [ProjectModel] {
        projetsViewModel.rankedProjects(for: searchQuery)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? darkBackground : Color(.systemBackground))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    AppBarViewComponets(
                        title: "GitPub",
                        isSearch: true,
                        onSearchTextChanged: { text in
                            scheduleSearch(with: text)
                        }
                    )

                    ScrollView {
                        LazyVStack {
                            ForEach(rankedProjects, id: \.id) { project in
                                ShortProjectInfoCardViewComponets(
                                    model: project,
                                    isStarred: projetsViewModel.isStarred(projectID: project.id),
                                    starsCount: projetsViewModel.displayedStarCount(for: project),
                                    onToggleStar: {
                                        projetsViewModel.toggleStar(for: project.id)
                                    },
                                    onTap: {
                                        selectedProjectForNavigation = project
                                    },
                                    onLongPress: {
                                        withAnimation(
                                            .spring(
                                                response: 0.35,
                                                dampingFraction: 0.85
                                            )
                                        ) {
                                            previewProject = project
                                            languageViewModel.loadLanguages(
                                                for: project.id
                                            )
                                        }
                                    }
                                ).onAppear {
                                    // Если это последний элемент в массиве — грузим следующую страницу
                                    if project.id == rankedProjects.last?.id {
                                        projetsViewModel.loadProjects(
                                            query: normalizedQuery,
                                            isPopular: true,
                                            pageSize: pageSize
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)
                    .refreshable {
                        await refreshProjectsIfNeeded()
                    }
                    .overlay {
                        if projetsViewModel.isLoading {
                            ProgressView()
                        } else if rankedProjects.isEmpty {
                            EmptyView()
                        }
                    }
                    .onAppear {
                        if projetsViewModel.projects.isEmpty {
                            projetsViewModel.loadProjects(
                                query: normalizedQuery,
                                isPopular: true,
                                pageSize: pageSize,
                                isFirstPage: true
                            )
                        }
                    }
                }
                .blur(radius: previewProject == nil ? 0 : 4)
                .animation(.easeInOut(duration: 0.2), value: previewProject != nil)

                if let previewProject {
                    Group {
                        if colorScheme == .dark {
                            LinearGradient(
                                colors: [
                                    AppTheme.Overlay.darkTop,
                                    AppTheme.Overlay.darkBottom,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Color.black.opacity(0.25)
                        }
                    }
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.previewProject = nil

                        }
                    }

                    ProjectDetailedInfoCardViewComponents(
                        model: previewProject,
                        languages: languageViewModel.languages,
                        isStarred: projetsViewModel.isStarred(projectID: previewProject.id),
                        starsCount: projetsViewModel.displayedStarCount(for: previewProject),
                        onToggleStar: {
                            projetsViewModel.toggleStar(for: previewProject.id)
                        }
                    )
                    .padding(.horizontal, 8)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .zIndex(1)
                    .onTapGesture {
                        // Блокируем закрытие при тапе по самой карточке
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedProjectForNavigation) { selectedProject in
                ProjectDetailView(
                    projectID: selectedProject.id,
                    initialProject: selectedProject,
                    projectViewModel: projetsViewModel
                )
            }
        }
    }

    private var normalizedQuery: String? {
        let value = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func scheduleSearch(with text: String) {
        searchDebounceWorkItem?.cancel()
        searchQuery = text

        let workItem = DispatchWorkItem {
            guard normalizedQuery != nil else { return }
            projetsViewModel.loadProjects(
                query: normalizedQuery,
                isPopular: true,
                pageSize: pageSize,
                isFirstPage: true
            )
        }

        searchDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    @MainActor
    private func refreshProjectsIfNeeded() async {
        guard normalizedQuery != nil else { return }

        projetsViewModel.loadProjects(
            query: normalizedQuery,
            isPopular: true,
            pageSize: pageSize,
            isFirstPage: true
        )

        while projetsViewModel.isLoading {
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
    }
}

#Preview {
    HomeView(
        projetsViewModel: ProjectViewModel(),
        languageViewModel: LanguageViewModel()
    )
}
