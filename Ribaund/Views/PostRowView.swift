//
//  PostRowView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    @ObservedObject var service: WordPressService // Pass service to use its helpers

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(service.stripHTML(from: post.title?.rendered ?? "no hay"))
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(service.formatDate(post.date))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
            
            Spacer()
            
            // Image Display
            if let urlString = post.featuredImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            }
        }
        .padding(.vertical, 4)
    }
}
