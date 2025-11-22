//
//  PostDetailView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var service: WordPressService
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var showCommentForm = false
    
    private let imageHeaderHeight: CGFloat = 250
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geometry in
                        self.imageHeader(geometry: geometry)
                    }
                    .frame(height: imageHeaderHeight)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(service.stripHTML(from: post.title?.rendered ?? "Başlıksız Makale"))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(service.formatDate(post.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        if let contentRendered = post.content?.rendered {
                            Text(service.formatContentText(from: contentRendered))
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                        } else {
                            Text("Bu makalenin içeriği şu anda mevcut değil.").font(.body).foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    CommentsSectionView(postId: post.id, service: service, showCommentForm: $showCommentForm)
                        .padding(.horizontal)
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                        .id("comments")
                    
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.top)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        // MARK: - Yoruma Kaydırma Butonu (Badge ile)
                        Button {
                            withAnimation {
                                proxy.scrollTo("comments", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "message.bubble.left.and.text")
                                .foregroundColor(.gray)
                                .overlay(
                                    Group {
                                        if let count = post.commentCount, count > 0 {
                                            Text("\(count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .frame(minWidth: 15, minHeight: 15)
                                                .background(Circle().fill(Color.red))
                                                .offset(x: 10, y: -10)
                                        }
                                    }
                                    , alignment: .topTrailing
                                )
                        }
                        
                        // Favori Butonu
                        Button {
                            favoritesManager.toggleFavorite(post: post)
                        } label: {
                            Image(systemName: favoritesManager.isFavorite(post: post) ? "heart.fill" : "heart")
                                .foregroundColor(favoritesManager.isFavorite(post: post) ? .red : .gray)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCommentForm) {
            CommentFormView(postId: post.id, service: service, isPresented: $showCommentForm)
        }
        .task {
            await service.fetchComments(forPostId: post.id)
        }
    }
    
    // MARK: - Header Görsel Fonksiyonu (Optimizasyonlu)
    private func imageHeader(geometry: GeometryProxy) -> some View {
        let minY = geometry.frame(in: .global).minY
        let dynamicHeight = max(0, imageHeaderHeight + minY)
        let scaleFactor = (minY > 0) ? 1.0 + (minY / imageHeaderHeight) * 0.5 : 1.0

        return Group {
            // CRITICAL CHANGE: detailImageURL kullanılıyor (daha yüksek çözünürlüklü görsel)
            if let urlString = post.detailImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "photo.fill").resizable().aspectRatio(contentMode: .fit).foregroundColor(.gray)
                    } else {
                        // ProgressView, yükleme durumunda
                        ProgressView()
                    }
                }
                .frame(width: geometry.size.width, height: dynamicHeight)
                .clipped()
                .scaleEffect(scaleFactor)
                .offset(y: (minY > 0) ? -minY : 0)
            } else {
                Rectangle().fill(Color(UIColor.systemGray5)).frame(width: geometry.size.width, height: dynamicHeight)
                    .overlay(
                        VStack { Image(systemName: "photo.fill").font(.largeTitle).foregroundColor(.gray)
                            Text("Görsel Mevcut Değil").foregroundColor(.gray) }
                    ).offset(y: (minY > 0) ? -minY : 0)
            }
        }
    }
}
