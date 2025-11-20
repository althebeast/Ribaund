//
//  ErrorView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import SwiftUI

// MARK: - Error View
struct ErrorView: View {
    let error: String
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
            Text("Connection Error")
                .font(.headline)
            Text(error)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

