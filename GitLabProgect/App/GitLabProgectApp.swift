//
//  GitLabProgectApp.swift
//  GitLabProgect
//
//  Created by Жасмина on 29.04.2026.
//

import SwiftUI

@main
struct GitLabProgectApp: App {
    private let projectsService: any ProjectsServicing = ProjectsService()
    
    var body: some Scene {
        WindowGroup {
            HomeView(projetsViewModel: ProjectViewModel(projectsService: projectsService))
        }
    }
}
