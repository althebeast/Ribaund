//
//  PostDetailView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var service: WordPressService // Inject the service
    
    // Header image height
    private let imageHeaderHeight: CGFloat = 250
    
    var body: some View {
        // GeometryReader is essential for the parallax scroll effect
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // 1. Featured Image Header with Parallax
                    self.imageHeader(geometry: geometry)
                    
                    // 2. Content Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Title
                        Text(service.stripHTML(from: post.title?.rendered ?? "Untitled Article"))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        // Metadata (Date)
                        HStack {
                            Image(systemName: "calendar")
                            Text(service.formatDate(post.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Article Content
                        if let contentRendered = post.content?.rendered {
                            Text(service.formatContentText(from: contentRendered))
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6) // Improved readability
                        } else {
                            Text("Content for this article is currently unavailable.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top) // Allow the image to stretch to the top edge
    }
    
    /// Generates the AsyncImage with Parallax/Scroll-Zoom effect
    private func imageHeader(geometry: GeometryProxy) -> some View {
        let minY = geometry.frame(in: .global).minY
        let dynamicHeight = max(0, imageHeaderHeight + minY)
        let scaleFactor = (minY > 0) ? 1.0 + (minY / imageHeaderHeight) * 0.5 : 1.0

        return Group {
            if let urlString = post.featuredImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: dynamicHeight)
                            .clipped()
                            .scaleEffect(scaleFactor)
                            // This offset creates the parallax effect
                            .offset(y: (minY > 0) ? -minY : 0)
                    } else {
                        // Placeholder (gray box)
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: geometry.size.width, height: dynamicHeight)
                            .overlay(ProgressView())
                            .offset(y: (minY > 0) ? -minY : 0)
                    }
                }
            } else {
                // Default placeholder if no image URL exists
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: geometry.size.width, height: dynamicHeight)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No Image Available")
                                .foregroundColor(.gray)
                        }
                    )
                    .offset(y: (minY > 0) ? -minY : 0)
            }
        }
        .frame(height: imageHeaderHeight) // Ensure the image section maintains its base height
    }
}
