//
//  FavoritesManager.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import Foundation
import Combine

/// Manages favorited posts using AppStorage for persistence.
class FavoritesManager: ObservableObject {
    @Published var favoritePosts: [Post] = []
    
    private let favoritesKey = "favoritePosts"

    init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let savedData = UserDefaults.standard.data(forKey: favoritesKey),
           // Use JSONDecoder to decode the array of Post objects
           let decodedPosts = try? JSONDecoder().decode([Post].self, from: savedData) {
            favoritePosts = decodedPosts
        }
    }

    private func saveFavorites() {
        if let encodedData = try? JSONEncoder().encode(favoritePosts) {
            UserDefaults.standard.set(encodedData, forKey: favoritesKey)
            // Notify views to refresh
            objectWillChange.send()
        }
    }

    func isFavorite(post: Post) -> Bool {
        // Check if a post with the same ID exists in the favorites list
        return favoritePosts.contains(where: { $0.id == post.id })
    }

    func toggleFavorite(post: Post) {
        if let index = favoritePosts.firstIndex(where: { $0.id == post.id }) {
            // Post is already a favorite, remove it
            favoritePosts.remove(at: index)
        } else {
            // Post is not a favorite, add it
            favoritePosts.append(post)
        }
        saveFavorites()
    }
}
