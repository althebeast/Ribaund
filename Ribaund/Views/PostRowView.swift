//
//  PostRowView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    @ObservedObject var service: WordPressService

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.stripHTML(from: post.title?.rendered ?? "Başlıksız Haber"))
                        .font(.system(.headline, design: .default))
                        .fontWeight(.medium)
                        .lineLimit(nil)
                        .foregroundColor(.primary)
                    Text(service.formatDate(post.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // CRITICAL CHANGE: rowImageURL kullanılıyor (daha küçük görsel boyutu)
                if let urlString = post.rowImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            // Başarılı görsel yükleme
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            // Hata veya görsel yok
                            Image(systemName: "photo.fill").resizable().aspectRatio(contentMode: .fit).foregroundColor(.gray)
                        } else {
                            // Yükleniyor durumu için ProgressView
                            ProgressView()
                        }
                    }
                    .frame(width: 100, height: 70)
                    .cornerRadius(10)
                    .clipped()
                } else {
                     Image(systemName: "photo.fill").resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 70)
                        .cornerRadius(10)
                        .foregroundColor(Color(UIColor.systemGray5))
                }
            }
            .padding(.vertical, 12)
            
            Divider()
        }
    }
}
