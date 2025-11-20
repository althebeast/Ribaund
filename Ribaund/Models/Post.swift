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
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, content
        case embedded = "_embedded"
    }

    let embedded: Embedded?
    
    // 🌟 ENHANCED ROBUST IMAGE URL COMPUTATION 🌟
    var featuredImageURL: String? {
        // 1. Try to get the thumbnail size (preferred)
        if let thumbnailURL = embedded?.featuredMedia?.first?.mediaDetails?.sizes?.thumbnail?.sourceURL {
            return thumbnailURL
        }
        // 2. Fallback to the 'full' size if thumbnail is missing
        if let fullURL = embedded?.featuredMedia?.first?.mediaDetails?.sizes?.full?.sourceURL {
            return fullURL
        }
        // 3. Fallback to the 'medium' size if both are missing
        if let mediumURL = embedded?.featuredMedia?.first?.mediaDetails?.sizes?.medium?.sourceURL {
            return mediumURL
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
    }
    
    struct MediaDetails: Codable {
        let sizes: Sizes?
    }
    
    struct Sizes: Codable {
        let thumbnail: SourceDetails?
        let medium: SourceDetails? // Added fallback size
        let full: SourceDetails?    // Added fallback size
    }
    
    struct SourceDetails: Codable {
        let sourceURL: String
        
        enum CodingKeys: String, CodingKey {
            case sourceURL = "source_url"
        }
    }
}
