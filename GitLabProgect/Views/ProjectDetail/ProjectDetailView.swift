import SwiftUI

struct ProjectDetailView: View {
    let projectID: Int
    let initialProject: ProjectModel

    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private let darkBackground = AppTheme.Palette.darkBackground
    private let darkSurface = AppTheme.Palette.darkSurface
    private let darkSecondarySurface = AppTheme.Palette.darkSecondarySurface

    private var project: ProjectModel {
        projectViewModel.projectDetails(for: projectID) ?? initialProject
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var subtitleColor: Color {
        colorScheme == .dark ? .white.opacity(0.76) : .secondary
    }

    private var chipBackground: Color {
        colorScheme == .dark ? darkSecondarySurface : Color.purple.opacity(0.10)
    }

    private var chipForeground: Color {
        colorScheme == .dark ? .white.opacity(0.90) : .purple
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? darkBackground : Color(.systemBackground))
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    factsSection
                    topicsSection
                    extraSection
                }
                .padding(.horizontal)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }

            if projectViewModel.isDetailLoading(for: projectID), projectViewModel.projectDetails(for: projectID) == nil {
                ProgressView()
                    .padding(20)
                    .background(colorScheme == .dark ? darkSurface : Color(.systemBackground))
                    .cornerRadius(14)
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task {
            projectViewModel.loadProjectDetails(projectID: projectID)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                avatarView(url: project.avatarUrl)

                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.title3.bold())
                        .foregroundColor(titleColor)

                    if let description = project.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(subtitleColor)
                    } else {
                        Text("Описание пока отсутствует")
                            .font(.subheadline)
                            .foregroundColor(subtitleColor)
                    }
                }

                Spacer(minLength: 0)
            }

            if let error = projectViewModel.detailError(for: projectID) {
                HStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                        .lineLimit(2)
                    Spacer()
                    Button("Повторить") {
                        projectViewModel.loadProjectDetails(projectID: projectID, forceRefresh: true)
                    }
                    .font(.caption.bold())
                }
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? darkSurface : Color(.systemBackground))
        .cornerRadius(16)
    }

    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Интересные факты")
                .font(.headline)
                .foregroundColor(titleColor)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCard(title: "Stars", value: "\(projectViewModel.displayedStarCount(for: project))", icon: "star.fill")
                statCard(title: "Forks", value: "\(project.forksCount ?? 0)", icon: "arrow.triangle.branch")
                statCard(title: "Commits", value: commitCountText, icon: "point.3.connected.trianglepath.dotted")
            }
        }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Теги")
                .font(.headline)
                .foregroundColor(titleColor)

            if let topics = project.topics, !topics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(chipBackground)
                                .foregroundColor(chipForeground)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                Text("Тегов пока нет")
                    .font(.subheadline)
                    .foregroundColor(subtitleColor)
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? darkSurface : Color(.systemBackground))
        .cornerRadius(16)
    }

    private var extraSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let activity = formattedLastActivity {
                row(icon: "clock", title: "Последняя активность", value: activity)
            }

            row(icon: "externaldrive", title: "Размер репозитория", value: repositorySizeText)

            if let webUrl = project.webUrl {
                Button {
                    openURL(webUrl)
                } label: {
                    HStack {
                        Image(systemName: "safari")
                        Text("Открыть в браузере")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.purple.opacity(0.85))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? darkSurface : Color(.systemBackground))
        .cornerRadius(16)
    }

    private var commitCountText: String {
        if let commits = project.statistics?.commitCount {
            return "\(commits)"
        }
        return "-"
    }

    private var repositorySizeText: String {
        guard let bytes = project.statistics?.repositorySize else {
            return "-"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var formattedLastActivity: String? {
        guard let raw = project.lastActivityAt else { return nil }
        let date = Self.iso8601DateFormatter.date(from: raw) ?? Self.iso8601FallbackDateFormatter.date(from: raw)
        guard let date else { return raw }
        return Self.displayDateFormatter.string(from: date)
    }

    private func avatarView(url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 60, height: 60)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            case .failure:
                fallbackAvatar
            @unknown default:
                fallbackAvatar
            }
        }
        .frame(width: 60, height: 60)
        .background(colorScheme == .dark ? darkSecondarySurface : Color(.systemGray6))
        .clipShape(Circle())
    }

    private var fallbackAvatar: some View {
        Image(systemName: "shippingbox")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .foregroundColor(.gray)
            .frame(width: 60, height: 60)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
            Text(value)
                .font(.headline)
                .foregroundColor(titleColor)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundColor(subtitleColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(colorScheme == .dark ? darkSurface : Color(.systemBackground))
        .cornerRadius(14)
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 18)

            Text(title)
                .font(.subheadline)
                .foregroundColor(subtitleColor)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(titleColor)
        }
    }

    private static let iso8601DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FallbackDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        ProjectDetailView(
            projectID: ProjectModel.mock.id,
            initialProject: ProjectModel.mock,
            projectViewModel: ProjectViewModel()
        )
    }
}
