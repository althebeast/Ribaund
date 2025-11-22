//
//  WPPost.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//

import SwiftUI
import Foundation

struct Post: Identifiable, Codable, Hashable {
    let id: Int
    let date: String
    let title: Content?
    let content: Content?
    
    let featuredMediaId: Int?
    let embedded: Embedded?
    let links: Links?
    
    var commentCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, content, embedded = "_embedded", featuredMediaId = "featured_media", links = "_links"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.date = try container.decode(String.self, forKey: .date)
        self.title = try container.decodeIfPresent(Content.self, forKey: .title)
        self.content = try container.decodeIfPresent(Content.self, forKey: .content)
        self.featuredMediaId = try container.decodeIfPresent(Int.self, forKey: .featuredMediaId)
        self.embedded = try container.decodeIfPresent(Embedded.self, forKey: .embedded)
        self.links = try container.decodeIfPresent(Links.self, forKey: .links)
        
        self.commentCount = self.links?.replies?.first?.count
    }

    /// Listede kullanılacak, daha küçük ve hızlı yüklenen görsel URL'sini döndürür.
    var rowImageURL: String? {
        let sizes = embedded?.featuredMedia?.first?.mediaDetails?.sizes
        // 1. Medium boyutu dene (Hızlı yükleme için en iyi orta yol)
        if let mediumURL = sizes?.medium?.sourceURL { return mediumURL }
        // 2. Thumbnail dene
        if let thumbnailURL = sizes?.thumbnail?.sourceURL { return thumbnailURL }
        // 3. Hiçbiri yoksa orijinal kaynağı dene
        return embedded?.featuredMedia?.first?.sourceURL
    }

    /// Detay sayfasında kullanılacak, daha yüksek çözünürlüklü görsel URL'sini döndürür.
    var detailImageURL: String? {
        let sizes = embedded?.featuredMedia?.first?.mediaDetails?.sizes
        // 1. Full/Orijinal boyut dene
        if let fullURL = sizes?.full?.sourceURL { return fullURL }
        // 2. Orijinal kaynak URL'sini dene
        return embedded?.featuredMedia?.first?.sourceURL
    }

    struct Content: Codable, Hashable {
        let rendered: String
    }
    
    // MARK: - Links Model for Comment Count
    struct Links: Codable, Hashable {
        let replies: [LinkDetail]?
        enum CodingKeys: String, CodingKey {
            case replies
        }
    }

    struct LinkDetail: Codable, Hashable {
        let count: Int?
        enum CodingKeys: String, CodingKey {
            case count = "count"
        }
    }
    
    // Embedded and Media models (unchanged)
    struct Embedded: Codable, Hashable {
        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
        }
        let featuredMedia: [FeaturedMedia]?
    }
    
    struct FeaturedMedia: Codable, Hashable {
        let mediaDetails: MediaDetails?
        let sourceURL: String?
        
        enum CodingKeys: String, CodingKey {
            case mediaDetails
            case sourceURL = "source_url"
        }
    }
    
    struct MediaDetails: Codable, Hashable {
        let sizes: Sizes?
        let sourceURL: String?
        
        enum CodingKeys: String, CodingKey {
            case sizes
            case sourceURL = "source_url"
        }
    }
    
    struct Sizes: Codable, Hashable {
        let thumbnail: SourceDetails?
        let medium: SourceDetails?
        let full: SourceDetails?
    }
    
    struct SourceDetails: Codable, Hashable {
        let sourceURL: String
        
        enum CodingKeys: String, CodingKey {
            case sourceURL = "source_url"
        }
    }
}
