import SwiftUI

struct ShortProjectInfoCardViewComponets: View {
    var model: ProjectModel

//    let tagName: String
    @State private var isLiked: Bool = false
    var body: some View {
        HStack(spacing: 12) {  // Добавил отступ между аватаркой и текстом
            _AvatarView(imageURL: model.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
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
                                : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)  // Убираем стандартное мигание кнопки

                }
                if let desctiption = model.description {
                    Text(desctiption)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)  // Чтобы текст не раздувал карточку
                }

               
            }
            Spacer()  // Выталкивает контент влево
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)  // Немного объема карточке
    }
}

private struct _AvatarView: View {
    let imageURL: URL?
    var size: CGFloat = 40

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
            Color(.systemGray6)
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5)
                .foregroundColor(.purple.opacity(0.6))
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
