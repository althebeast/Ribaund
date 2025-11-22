//
//  FavoritesView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @ObservedObject var service: WordPressService // Need service for PostDetailView injection

    var body: some View {
        NavigationView {
            Group {
                if favoritesManager.favoritePosts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Henüz Favori Yok")
                            .font(.headline)
                        Text("Buraya kaydetmek için herhangi bir haberde kalp ikonuna dokunun.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(favoritesManager.favoritePosts) { post in
                            ZStack {
                                NavigationLink(destination: PostDetailView(post: post, service: service)) { EmptyView() }
                                .opacity(0)
                                PostRowView(post: post, service: service)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .background(Color.clear)
                        }
                        // Add an empty row at the bottom for aesthetic space
                        Color.clear.frame(height: 20).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoriler")
        }
    }
}
