//
//  ContentView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//
import SwiftUI

// Renamed from ContentView to fit the TabView structure
struct NewsView: View {
    @ObservedObject var service: WordPressService
    @State private var selectedCategoryId: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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

                Group {
                    if !service.isCategoriesLoaded || service.isLoading && service.posts.isEmpty {
                        ProgressView("Haberler Yükleniyor...")
                            .scaleEffect(1.5)
                    } else if service.lastFetchError != nil {
                        ErrorView(error: service.lastFetchError ?? "Bilinmeyen bir hata oluştu.")
                    } else if service.posts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "newspaper.slash").font(.largeTitle).foregroundColor(.gray)
                            Text("Bu Kategoride Haber Bulunamadı").font(.headline)
                            Text("Farklı bir kategori seçmeyi veya internet bağlantınızı kontrol etmeyi deneyin.")
                                .font(.subheadline).multilineTextAlignment(.center).foregroundColor(.gray)
                        }.padding()
                    } else {
                        List {
                            ForEach(service.posts) { post in
                                if post.title != nil || post.content != nil {
                                    ZStack {
                                        NavigationLink(destination: PostDetailView(post: post, service: service)) { EmptyView() }
                                        .opacity(0)
                                        PostRowView(post: post, service: service)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                    .background(Color.clear)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            // Pull-to-refresh her zaman zorla yenileme yapar
                            await service.fetchPosts(for: selectedCategoryId, forceRefresh: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Haberler")
            .task {
                await service.fetchCategories()
                
                // Geri dönüldüğünde tekrar yüklenmeyi önlemek için sadece posts boşsa çek
                if service.posts.isEmpty {
                    await service.fetchPosts()
                }
            }
            .onChange(of: selectedCategoryId) { newId in
                // Kategori değiştiğinde zorla yenileme yapar
                Task { await service.fetchPosts(for: newId, forceRefresh: true) }
            }
        }
        .navigationViewStyle(.stack)
    }
}
