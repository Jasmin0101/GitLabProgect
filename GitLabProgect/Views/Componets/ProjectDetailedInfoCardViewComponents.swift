import SwiftUI

struct ProjectDetailedInfoCardViewComponents: View {
    let model:ProjectModel
    let languages: [String]
    @State var starsCount: Int
    @State private var isLiked: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let cardColor = AppTheme.Palette.darkSurface
    private let chipColor = AppTheme.Palette.darkSecondarySurface
    
    private var titleColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var ownerColor: Color {
        colorScheme == .dark ? .white.opacity(0.72) : .purple
    }
    
    private var countColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var starIdleBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.gray.opacity(0.1)
    }
    
    private var starActiveBackground: Color {
        colorScheme == .dark ? Color.yellow.opacity(0.25) : Color.yellow.opacity(0.2)
    }
    
    private var descriptionColor: Color {
        colorScheme == .dark ? .white.opacity(0.82) : .secondary
    }
    
    private var languageChipBackground: Color {
        colorScheme == .dark ? chipColor : Color.purple.opacity(0.1)
    }
    
    private var languageChipText: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .purple
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? cardColor : Color(.systemBackground)
    }
    
    private var cardShadow: Color {
        colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.1)
    }
    
    private var cardShadowRadius: CGFloat {
        colorScheme == .dark ? 14 : 8
    }
    
    init(model: ProjectModel, languages: [String]) {
            self.model = model
            self.languages = languages
            // Инициализируем State начальным значением из модели
            _starsCount = State(initialValue: model.starCount ?? 0)
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Верхняя часть
            HStack(alignment: .top, spacing: 12) {
                _AvatarView(imageURL: model.avatarUrl, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.title3.bold())
                        .foregroundColor(titleColor)
                    if let owner = model.owner {
                        Text("@\(owner.name)")
                            .font(.subheadline)
                            .foregroundColor(ownerColor)
                    }
                }
                
                Spacer()
                
                // Кликабельная звездочка
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                        starsCount += isLiked ? 1 : -1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "star.fill" : "star")
                            .foregroundColor(isLiked ? .yellow : .gray)
                        Text("\(starsCount)")
                            .font(.system(.subheadline, design: .rounded))
                            .bold()
                            .foregroundColor(countColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isLiked ? starActiveBackground : starIdleBackground)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain) // Убираем стандартное мигание кнопки
            }
            
            // Прокручиваемое описание
            if let description = model.description {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(description)
                        .font(.body)
                        .foregroundColor(descriptionColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 80) // Ограничиваем высоту зоны прокрутки
            }
            
            // Список языков
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(languages, id: \.self) { lang in
                        Text(lang)
                            .font(.caption2.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(languageChipBackground)
                            .foregroundColor(languageChipText)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: cardShadow, radius: cardShadowRadius, x: 0, y: 4)
        .padding(.horizontal)
    }
}

private struct _AvatarView: View {
    let imageURL: URL?
    var size: CGFloat = 60
    @Environment(\.colorScheme) private var colorScheme
    
    private let strokeColor: Color = .purple.opacity(0.5)
    private let strokeWidth: CGFloat = 2

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty, .failure:
                        avatarPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(strokeColor, lineWidth: strokeWidth))
    }

    private var avatarPlaceholder: some View {
        ZStack {
            colorScheme == .dark
                ? AppTheme.Palette.darkSecondarySurface
                : Color(.systemGray6)
            // Пользователь вверх тормашками
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5)
                .rotationEffect(.degrees(180)) // ПЕРЕВОРОТ
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.75) : .purple.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGray6).ignoresSafeArea()
        ProjectDetailedInfoCardViewComponents(
            model: ProjectModel.mock,
                    languages: ["Swift", "SwiftUI", "Combine", "GraphQL", "Python", "Rust", "C++"],
        )
    }
}
