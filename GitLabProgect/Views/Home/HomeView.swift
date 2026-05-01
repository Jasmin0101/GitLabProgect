//
//  HomeView.swift
//  GitLabProgect
//
//  Created by Жасмина on 29.04.2026.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var projetsViewModel: ProjectViewModel
    
    var body: some View {
        
        AppBarViewComponets(title: "Mina", isSearch: true)
        
        ScrollView{
            ForEach(projetsViewModel.projects , id: \.id){
                project in
                ShortProjectInfoCardViewComponets(model: project)
                
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
            projetsViewModel.loadProjects()
        }
    }
}

#Preview {
    HomeView(projetsViewModel:  ProjectViewModel())
}
