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
    @Environment(\.colorScheme) private var colorScheme
    
    private let darkBackground = AppTheme.Palette.darkBackground
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? darkBackground : Color(.systemBackground))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppBarViewComponets(title: "GitPub", isSearch: true)
                
                ScrollView{
                    ForEach(projetsViewModel.projects , id: \.id){
                        project in
                        ShortProjectInfoCardViewComponets(
                            model: project,
                            onLongPress: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    previewProject = project
                                }
                            }
                        )
                    }
                }.padding(.horizontal)
                .overlay{
                    if projetsViewModel.isLoading{
                        ProgressView()
                    } else if projetsViewModel.projects.isEmpty {
                        EmptyView()
                    }
                }
                .onAppear{
                    projetsViewModel.loadProjects(isPopular: true)
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
                                AppTheme.Overlay.darkBottom
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
                    languages: languageViewModel.languages
                )
                .padding(.horizontal, 8)
                .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
                .zIndex(1)
                .onTapGesture {
                    // Блокируем закрытие при тапе по самой карточке
                }
            }
        }
    }
}

#Preview {
    HomeView( projetsViewModel:  ProjectViewModel(),languageViewModel:  LanguageViewModel())
}
