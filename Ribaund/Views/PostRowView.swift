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
        // This is the actual content that is laid out in the list
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) { // Increased horizontal spacing
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.stripHTML(from: post.title?.rendered ?? "Untitled Post"))
                        .font(.system(.headline, design: .default))
                        .fontWeight(.medium)
                        .lineLimit(nil) // Set to nil to allow unlimited lines
                        .foregroundColor(.primary)
                    
                    Text(service.formatDate(post.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                // 💡 FIX: Force the V-Stack to calculate its full height, allowing the title to wrap fully.
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Image Display
                if let urlString = post.featuredImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Image(systemName: "photo.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 100, height: 70) // Slightly wider image
                    .cornerRadius(10) // More rounded corners
                    .clipped()
                } else {
                     Image(systemName: "photo.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 70)
                        .cornerRadius(10)
                        .foregroundColor(Color(UIColor.systemGray5))
                }
            }
            .padding(.vertical, 12) // Increased vertical padding for breathing room
            
            Divider()
        }
    }
}
