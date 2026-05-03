import SwiftUI

struct FavoritesView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var selectedProjectForNavigation: ProjectModel? = nil
    @Environment(\.colorScheme) private var colorScheme

    private let darkBackground = AppTheme.Palette.darkBackground

    var body: some View {
        ZStack {
            (colorScheme == .dark ? darkBackground : Color(.systemBackground))
                .ignoresSafeArea()

            if projectViewModel.favoriteProjects.isEmpty {
                ContentUnavailableView(
                    "Пока нет избранного",
                    systemImage: "star",
                    description: Text("Добавьте проект в избранное, чтобы он появился здесь.")
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(projectViewModel.favoriteProjects, id: \.id) { project in
                            ShortProjectInfoCardViewComponets(
                                model: project,
                                isStarred: projectViewModel.isStarred(projectID: project.id),
                                starsCount: projectViewModel.displayedStarCount(for: project),
                                onToggleStar: {
                                    projectViewModel.toggleStar(for: project.id)
                                },
                                onTap: {
                                    selectedProjectForNavigation = project
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Избранное")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedProjectForNavigation) { selectedProject in
            ProjectDetailView(
                projectID: selectedProject.id,
                initialProject: selectedProject,
                projectViewModel: projectViewModel
            )
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView(projectViewModel: ProjectViewModel())
    }
}
