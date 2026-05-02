import SwiftUI

struct AppBarViewComponets: View { // Аналог: StatelessWidget или StatefulWidget
    var title: String?
    var isSearch: Bool = false
    var onSearchTextChanged: ((String) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    // Аналог: TextEditingController + setState()
    @State private var isSearchActive = false
    @State private var searchText = ""

    private var darkSurface: Color {
        AppTheme.Palette.darkSurface
    }

    private var barTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var searchFieldBackground: Color {
        colorScheme == .dark ? darkSurface : Color(.systemGray6)
    }

    private func updateSearch(_ text: String) {
        onSearchTextChanged?(text)
    }

    var body: some View {
        // --- Аналог: Column(children: [...], crossAxisAlignment: CrossAxisAlignment.start) ---
        VStack(spacing: 0) {

            // --- Аналог: Row(children: [...]) ---
            HStack {
                if isSearchActive {
                    // --- Аналог: Container(decoration: BoxDecoration(...), child: Row(...)) ---
                    HStack {
                        // --- Аналог: Icon(Icons.search) ---
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        // --- Аналог: TextField(controller: ...) ---
                        TextField("Поиск...", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .foregroundColor(barTextColor)
                            .onChange(of: searchText) { newValue in
                                updateSearch(newValue)
                            }

                        if !searchText.isEmpty {
                            // --- Аналог: IconButton(onPressed: () {}, icon: Icon(Icons.clear)) ---
                            Button(action: {
                                searchText = ""
                                updateSearch("")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(searchFieldBackground)
                    // --- Аналог: BorderRadius.circular(10) ---
                    .cornerRadius(10)
                    // --- Аналог: AnimatedSwitcher или SlideTransition ---
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    // --- Аналог: TextButton(onPressed: () {}, child: Text("Отмена")) ---
                    Button("Отмена") {
                        withAnimation(.spring()) {
                            isSearchActive = false
                            searchText = ""
                            updateSearch("")
                        }
                    }
                    .padding(.leading, 8)

                } else {
                    // --- Аналог: Text("GitLab", style: TextStyle(fontWeight: FontWeight.bold)) ---
                    Text(title ?? "GitLab Project")
                        .font(.title2.bold())
                        .foregroundColor(barTextColor)

                    // --- Аналог: Spacer() ---
                    Spacer()

                    if isSearch {
                        Button(action: {
                            withAnimation(.spring()) {
                                isSearchActive = true
                            }
                        }) {
                            // --- Аналог: Container(shape: BoxShape.circle, child: Icon(...)) ---
                            Image(systemName: "magnifyingglass")
                                .padding(10)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding()

            // --- Аналог: Divider(height: 1) ---
            Divider()
                .overlay(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear)
        }
    }
}

#Preview {
    AppBarViewComponets(title: "Mina", isSearch: true)
}
