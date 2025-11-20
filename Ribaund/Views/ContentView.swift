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
            
            VStack(spacing: 0) {
                // 1. Segmented Picker (Sticky to the top)
                if service.isCategoriesLoaded {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(service.categories, id: \.id) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // 2. Content Area (Loading, Error, or List)
                Group {
                    if !service.isCategoriesLoaded || service.isLoading {
                        ProgressView("Yükleniyor...")
                            .scaleEffect(1.5)
                    } else if service.lastFetchError != nil {
                        ErrorView(error: service.lastFetchError ?? "An unknown error occurred.")
                    } else if service.posts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "newspaper.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Bu kategoride haber bulunamadı.")
                                .font(.headline)
                            Text("Lütfen başka bir kategori seçin ve ya internet bağlantınızı kontrol edin.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // Display the list of posts
                        List {
                            ForEach(service.posts) { post in
                                if post.title != nil || post.content != nil {
                                    // 💡 REMOVED THE ARROW: Use a ZStack or a hidden NavigationLink to suppress the indicator
                                    ZStack {
                                        // Invisible NavigationLink to handle the navigation action
                                        NavigationLink(destination: PostDetailView(post: post, service: service)) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        
                                        // The actual, styled row content
                                        PostRowView(post: post, service: service)
                                    }
                                    .listRowSeparator(.hidden) // Hide the separator
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)) // Custom padding
                                    .background(Color.clear)
                                }
                            }
                        }
                        .listStyle(.plain) // Use plain style for clean modern look
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Ribaund ")
            .task {
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
