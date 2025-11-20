//
//  WordPressService.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//
import SwiftUI
import Combine

class WordPressService: ObservableObject {
    private let baseURL = "https://ribaund.com/wp-json/wp/v2"

    @Published var posts: [Post] = []
    @Published var categories: [Category] = [Category(id: 0, name: "All News")]
    @Published var isLoading: Bool = false
    @Published var lastFetchError: String? = nil
    @Published var isCategoriesLoaded: Bool = false

    
    /// Helper functions (date formatting, HTML stripping, content formatting)
    func formatDate(_ dateString: String) -> String {
        // 1. Try ISO8601 with flexible options (Standard WordPress format)
        let isoFormatter = ISO8601DateFormatter()
        // Removed .withFractionalSeconds to handle dates without milliseconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // 2. Fallback for potential alternative formats (if ISO8601 fails)
        let dateFormatter = DateFormatter()
        // Example fallback format: "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return "Unknown Date"
    }
    
    func stripHTML(from text: String) -> String {
        var cleanedText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        cleanedText = cleanedText.replacingOccurrences(of: "&amp;", with: "&")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8217;", with: "'")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8220;", with: "\"")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8221;", with: "\"")
        
        // Explicitly handle common entities like Non-Breaking Space
        cleanedText = cleanedText.replacingOccurrences(of: "&nbsp;", with: " ")
        
        return cleanedText
    }
    
    func formatContentText(from html: String) -> String {
        var formattedText = html
        
        // 1. Replace block elements with newlines/separators
        formattedText = formattedText.replacingOccurrences(of: "</?p.*?>", with: "\n\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?h[1-6].*?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "<br\\s*?/?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?div.*?>|</?span.*?>|</?figure.*?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "<li.*?>", with: "\n• ", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?ul.*?>|</?ol.*?>|</?li>", with: "", options: .regularExpression, range: nil)
        
        // 2. Remove all remaining HTML tags
        formattedText = formattedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // 3. Decode common HTML entities (including &nbsp; fix)
        formattedText = formattedText.replacingOccurrences(of: "&nbsp;", with: " ") // 💡 The new fix for &nbsp;
        formattedText = formattedText.replacingOccurrences(of: "&amp;", with: "&")
        formattedText = formattedText.replacingOccurrences(of: "&gt;", with: ">")
        formattedText = formattedText.replacingOccurrences(of: "&lt;", with: "<")
        formattedText = formattedText.replacingOccurrences(of: "&#8217;", with: "'")
        formattedText = formattedText.replacingOccurrences(of: "&#8220;", with: "\"")
        formattedText = formattedText.replacingOccurrences(of: "&#8221;", with: "\"")
        
        // 4. Clean up spacing and newlines
        formattedText = formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
        formattedText = formattedText.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression, range: nil)
        
        return formattedText
    }
    
    func fetchCategories() async {
        let urlString = "\(baseURL)/categories?per_page=100"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedCategories = try JSONDecoder().decode([Category].self, from: data)

            await MainActor.run {
                self.categories = [Category(id: 0, name: "All News")]
                self.categories.append(contentsOf: decodedCategories.filter { $0.id != 1 })
                self.isCategoriesLoaded = true // Mark categories as loaded
            }
        } catch {
            await MainActor.run {
                 self.isCategoriesLoaded = true // Mark as loaded even on failure to stop spinner
            }
        }
    }

    func fetchPosts(for categoryId: Int? = nil) async {
        await MainActor.run {
            self.isLoading = true
            self.lastFetchError = nil
        }
        
        var urlString = "\(baseURL)/posts?per_page=15&_embed=true"
        
        if let id = categoryId, id != 0 {
            urlString += "&categories=\(id)"
        }
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.isLoading = false
                self.lastFetchError = "Invalid API URL."
            }
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.isLoading = false
                    self.lastFetchError = "Received non-HTTP response."
                }
                return
            }

            guard httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.isLoading = false
                    self.lastFetchError = "Server error. Status: \(httpResponse.statusCode)."
                }
                return
            }
            
            let decodedPosts = try JSONDecoder().decode([Post].self, from: data)

            await MainActor.run {
                self.posts = decodedPosts
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastFetchError = "Decoding failed: \(error.localizedDescription)"
            }
        }
    }
}
