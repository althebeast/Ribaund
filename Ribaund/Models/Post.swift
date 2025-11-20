//
//  WPPost.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//

import SwiftUI
import Foundation

// Represents a single WordPress Post object.
// Made title and content optional as a final failsafe against malformed API responses.
struct Post: Identifiable, Codable {
    let id: Int
    let date: String
    let title: Content?
    let content: Content?
    
    // Add the featured_media ID to the model
    let featuredMediaId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, content
        case embedded = "_embedded"
        case featuredMediaId = "featured_media" // Map "featured_media" ID
    }

    let embedded: Embedded?
    
    // 🌟 ULTIMATE ROBUST IMAGE URL COMPUTATION 🌟
    var featuredImageURL: String? {
        let media = embedded?.featuredMedia?.first
        
        // 1. Check for a high-level source_url directly on the mediaDetails object
        if let directURL = media?.mediaDetails?.sourceURL {
            return directURL
        }
        
        // 2. Try specific sizes via mediaDetails
        if let sizes = media?.mediaDetails?.sizes {
            // Check Full (most reliable size when others fail)
            if let fullURL = sizes.full?.sourceURL {
                return fullURL
            }
            // Check Thumbnail (best for list)
            if let thumbnailURL = sizes.thumbnail?.sourceURL {
                return thumbnailURL
            }
            // Check Medium (medium-quality fallback)
            if let mediumURL = sizes.medium?.sourceURL {
                return mediumURL
            }
        }
        
        // 3. Check for the main post image source directly on the media object itself
        if let mediaSourceURL = media?.sourceURL {
            return mediaSourceURL
        }
        
        return nil
    }

    struct Content: Codable {
        let rendered: String
    }
    
    struct Embedded: Codable {
        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
        }
        let featuredMedia: [FeaturedMedia]?
    }
    
    struct FeaturedMedia: Codable {
        let mediaDetails: MediaDetails?
        let sourceURL: String? // Added for ultimate fallback
        
        enum CodingKeys: String, CodingKey {
            case mediaDetails
            case sourceURL = "source_url" // Common high-level URL
        }
    }
    
    struct MediaDetails: Codable {
        let sizes: Sizes?
        let sourceURL: String?
        
        enum CodingKeys: String, CodingKey {
            case sizes
            case sourceURL = "source_url" // Common high-level URL
        }
    }
    
    struct Sizes: Codable {
        let thumbnail: SourceDetails?
        let medium: SourceDetails?
        let full: SourceDetails?
    }
    
    struct SourceDetails: Codable {
        let sourceURL: String
        
        enum CodingKeys: String, CodingKey {
            case sourceURL = "source_url"
        }
    }
}
