//
//  ContentView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var service = WordPressService()
    @State private var selectedCategoryId: Int = 0
    
    var body: some View {
        NavigationView {
            
            // 🌟 CLS FIX: Always draw the main VStack, use conditionals for content
            VStack {
                // Only show Picker once categories are loaded
                if service.isCategoriesLoaded {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(service.categories, id: \.id) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // 🌟 CLS FIX: The Group is forced to fill the space, preventing jumps 🌟
                Group {
                    if !service.isCategoriesLoaded || service.isLoading {
                        ProgressView("Loading News...")
                            .scaleEffect(1.5)
                    } else if service.lastFetchError != nil {
                        ErrorView(error: service.lastFetchError ?? "An unknown error occurred.")
                    } else if service.posts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "newspaper.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No News Found")
                                .font(.headline)
                            Text("Try selecting a different category or checking your internet connection.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // Display the list of posts
                        List(service.posts) { post in
                            if post.title != nil || post.content != nil {
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostRowView(post: post, service: service)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // ⬅️ THIS FIXES THE JUMP
            }
            .navigationTitle("Ribaund News")
            .task {
                // Ensure initial fetches run once when the view appears
                await service.fetchCategories()
                await service.fetchPosts()
            }
            .onChange(of: selectedCategoryId) { newId in
                Task {
                    await service.fetchPosts(for: newId)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WordPressService())
}
