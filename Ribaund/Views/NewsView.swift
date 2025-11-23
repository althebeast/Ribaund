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
    
    @State private var isSearchFocused: Bool = false
        
        // Arama debounce için görev
        @State private var searchTask: Task<Void, Never>?
    
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
                                    .onAppear {
                                                                            if let lastPost = service.posts.last, lastPost.id == post.id && service.canLoadMore {
                                                                                Task { await service.loadNextPage() }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                
                                                                // MARK: - Yükleme Göstergesi
                                                                if service.canLoadMore {
                                                                    HStack {
                                                                        Spacer()
                                                                        ProgressView("Daha Fazla Yükleniyor...")
                                                                        Spacer()
                                                                    }
                                                                    .padding(.vertical, 15)
                                                                    .listRowSeparator(.hidden)
                                                                } else if service.posts.count > 0 {
                                                                    Text("Listenin sonuna ulaştınız.")
                                                                        .font(.caption)
                                                                        .foregroundColor(.secondary)
                                                                        .frame(maxWidth: .infinity)
                                                                        .padding(.vertical, 10)
                                                                        .listRowSeparator(.hidden)
                                                                }
                                                            }
                                                            .listStyle(.plain)
                                                            .refreshable {
                                                                // Yenileme yaparken arama filtresini koru
                                                                await service.fetchPosts(for: selectedCategoryId, searchQuery: service.searchText.isEmpty ? nil : service.searchText, forceRefresh: true)
                                                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Haberler")
            // MARK: - Arama Özelliği
                        .searchable(text: $service.searchText, placement: .automatic, prompt: "Haberlerde Ara...")
                        .onSubmit(of: .search) {
                            // Submit edildiğinde hemen ara
                            searchTask?.cancel()
                            Task { await service.startSearch() }
                        }
                        .onChange(of: service.searchText) { newQuery in
                            // Debounce mekanizması: Kullanıcı yazmayı bıraktıktan 0.5 saniye sonra ara
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye bekle
                                // Eğer yeni sorgu boş değilse veya son yüklenen sorgu boş değilse (yani bir değişiklik varsa) ara.
                                if newQuery != service.lastLoadedSearchText {
                                    await service.startSearch()
                                }
                            }
                        }
                        
                        .task {
                            await service.fetchCategories()
                            if service.posts.isEmpty { await service.fetchPosts() }
                        }
                        .onChange(of: selectedCategoryId) { newId in
                            // Kategori değiştiğinde arama metnini sıfırla ve yeni kategoriyi yükle
                            service.searchText = ""
                            Task { await service.fetchPosts(for: newId, forceRefresh: true) }
                        }
        }
        .navigationViewStyle(.stack)
    }
}
