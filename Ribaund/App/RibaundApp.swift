//
//  RibaundApp.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//

import SwiftUI

@main
struct RibaundApp: App {
    // Initialize ObservableObjects once and inject them into the environment
        @StateObject private var service = WordPressService()
        @StateObject private var favoritesManager = FavoritesManager()
        @StateObject private var themeManager = ThemeManager()
        
        var body: some Scene {
            WindowGroup {
                TabView {
                    // 1. Haberler (News) Tab
                    NewsView(service: service)
                        .tabItem {
                            Label("Haberler", systemImage: "newspaper.fill")
                        }
                    
                    // 2. Favoriler (Favorites) Tab
                    FavoritesView(service: service)
                        .tabItem {
                            Label("Favoriler", systemImage: "heart.square.fill")
                        }
                    
                    // 3. Ayarlar (Settings) Tab
                    SettingsView()
                        .tabItem {
                            Label("Ayarlar", systemImage: "gearshape.fill")
                        }
                }
                // Apply managers to the entire environment
                .environmentObject(service)
                .environmentObject(favoritesManager)
                .environmentObject(themeManager)
                // Apply the custom color scheme preference from the ThemeManager
                .preferredColorScheme(themeManager.colorScheme)
            }
        }
    }
