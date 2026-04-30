import SwiftUI

struct AppBarViewComponets: View { // Аналог: StatelessWidget или StatefulWidget
    var title: String?
    var isSearch: Bool = false
    
    // Аналог: TextEditingController + setState()
    @State private var isSearchActive = false
    @State private var searchText = ""

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
                        
                        if !searchText.isEmpty {
                            // --- Аналог: IconButton(onPressed: () {}, icon: Icon(Icons.clear)) ---
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    // --- Аналог: BorderRadius.circular(10) ---
                    .cornerRadius(10)
                    // --- Аналог: AnimatedSwitcher или SlideTransition ---
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    // --- Аналог: TextButton(onPressed: () {}, child: Text("Отмена")) ---
                    Button("Отмена") {
                        withAnimation(.spring()) {
                            isSearchActive = false
                            searchText = ""
                        }
                    }
                    .padding(.leading, 8)
                    
                } else {
                    // --- Аналог: Text("GitLab", style: TextStyle(fontWeight: FontWeight.bold)) ---
                    Text(title ?? "GitLab Project")
                        .font(.title2.bold())
                    
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
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding()
            
            // --- Аналог: Divider(height: 1) ---
            Divider()
        }
    }
}

#Preview {
    AppBarViewComponets(title:"Mina")
}
