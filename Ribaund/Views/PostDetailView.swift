//
//  PostDetailView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    private static let service = WordPressService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(PostDetailView.service.stripHTML(from: post.title?.rendered ?? "An unknown error occurred."))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(nil)

                // 🎯 THIS IS THE CRITICAL LINE: It calls the cleanup function on the raw HTML.
                Text(PostDetailView.service.formatContentText(from: post.content?.rendered ?? "An unknown error occurred."))
                    .font(.body)
                    .lineLimit(nil)
            }
            .padding()
        }
        .navigationTitle(PostDetailView.service.stripHTML(from: post.title?.rendered ?? "An unknown error occurred."))
        .navigationBarTitleDisplayMode(.inline)
    }
}
