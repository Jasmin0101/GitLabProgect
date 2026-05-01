import SwiftUI

struct ShortProjectInfoCardViewComponets: View {
    var model: ProjectModel
    var onLongPress: (() -> Void)? = nil
    var onPressingChanged: ((Bool) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

//    let tagName: String
    @State private var isLiked: Bool = false
    
    private var darkCardColor: Color {
        AppTheme.Palette.darkSurface
    }
    
    private var titleColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var subtitleColor: Color {
        colorScheme == .dark ? .white.opacity(0.78) : .secondary
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? darkCardColor : Color(.systemBackground)
    }
    
    private var idleStarBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.gray.opacity(0.1)
    }
    
    var body: some View {
        HStack(spacing: 12) {  // Добавил отступ между аватаркой и текстом
            _AvatarView(imageURL: model.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline).lineLimit(1)
                        .foregroundColor(titleColor)
                    Spacer()
                    Button(action: {
                        withAnimation(
                            .spring(response: 0.3, dampingFraction: 0.6)
                        ) {
                            isLiked.toggle()
                           
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "star.fill" : "star")
                                .foregroundColor(isLiked ? .yellow : .gray)
                            
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isLiked
                                ? Color.yellow.opacity(0.2)
                                : idleStarBackground
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)  // Убираем стандартное мигание кнопки

                }
                if let desctiption = model.description {
                    Text(desctiption)
                        .font(.subheadline)
                        .foregroundColor(subtitleColor)
                        .lineLimit(2)  // Чтобы текст не раздувал карточку
                }

               
            }
            Spacer()  // Выталкивает контент влево
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.05), radius: colorScheme == .dark ? 10 : 5, x: 0, y: 2)
        .onLongPressGesture(
            minimumDuration: 0.35,
            pressing: { isPressing in
                onPressingChanged?(isPressing)
            },
            perform: {
                onLongPress?()
            }
        )
    }
}

private struct _AvatarView: View {
    let imageURL: URL?
    var size: CGFloat = 40
    @Environment(\.colorScheme) private var colorScheme

    // Настройки окантовки
    private let strokeColor: Color = .purple.opacity(0.5)  // Цвет линии
    private let strokeWidth: CGFloat = 2  // Толщина 2 пикселя

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        avatarPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
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
        .clipShape(Circle())  // Сначала обрезаем контент по кругу
        .overlay(
            // ДОБАВЛЯЕМ ОКАНТОВКУ ТУТ
            Circle()
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
    }

    private var avatarPlaceholder: some View {
        ZStack {
            colorScheme == .dark
                ? AppTheme.Palette.darkSecondarySurface
                : Color(.systemGray6)
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.75) : .purple.opacity(0.6))
        }
    }
}

#Preview {
    VStack {
        ShortProjectInfoCardViewComponets(
            model: ProjectModel.mock
        )

        ShortProjectInfoCardViewComponets(
            model: ProjectModel.mock
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
