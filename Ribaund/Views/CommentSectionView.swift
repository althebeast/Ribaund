//
//  CommentSectionView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import SwiftUI

struct CommentsSectionView: View {
    let postId: Int
    @ObservedObject var service: WordPressService
    @Binding var showCommentForm: Bool
    
    // Hatanın oluştuğu blok düzeltildi:
    // service.comments[postId] ifadesi açıkça [Comment]? olarak tip dönüşümüne zorlandı.
    var comments: [Comment] {
        (service.comments[postId] as [Comment]?) ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack {
                Text("Yorumlar (\(comments.count))")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Yorum Yap") {
                    showCommentForm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.9, green: 0.4, blue: 0.1))
            }
            
            if comments.isEmpty {
                Text("Bu habere henüz yorum yapılmamış.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(comment.authorName)
                                .font(.headline)
                                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.1))
                            Spacer()
                            Text(service.formatDate(comment.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(service.stripHTML(from: comment.content.rendered))
                            .font(.body)
                            .lineLimit(nil)
                            .padding(.bottom, 5)
                        
                        Divider()
                    }
                }
            }
        }
    }
}
