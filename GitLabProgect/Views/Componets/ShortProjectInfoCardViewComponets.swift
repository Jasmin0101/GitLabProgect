import SwiftUI

struct ShortProjectInfoCardViewComponets: View {
    var model: ProjectModel
    var isStarred: Bool = false
    var starsCount: Int = 0
    var onToggleStar: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil
    var onPressingChanged: ((Bool) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

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
        HStack(spacing: 12) {
            _AvatarView(imageURL: model.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(titleColor)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggleStar?()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundColor(isStarred ? .yellow : .gray)
                            Text("\(starsCount)")
                                .font(.system(.caption, design: .rounded))
                                .bold()
                                .foregroundColor(titleColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isStarred
                                ? Color.yellow.opacity(0.2)
                                : idleStarBackground
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                }
                if let desctiption = model.description {
                    Text(desctiption)
                        .font(.subheadline)
                        .foregroundColor(subtitleColor)
                        .lineLimit(2)
                }


            }
            Spacer()
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(16)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.05), radius: colorScheme == .dark ? 10 : 5, x: 0, y: 2)
        .onTapGesture {
            onTap?()
        }
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
    private let strokeColor: Color = .purple.opacity(0.5)
    private let strokeWidth: CGFloat = 2

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
        .clipShape(Circle())
        .overlay(
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
            model: ProjectModel.mock,
            isStarred: true,
            starsCount: 126
        )

        ShortProjectInfoCardViewComponets(
            model: ProjectModel.mock,
            isStarred: false,
            starsCount: 125
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
