//
//  Comment.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import Foundation

struct Comment: Identifiable, Decodable {
    let id: Int
    let authorName: String
    let date: String
    let content: Content
    
    enum CodingKeys: String, CodingKey {
        case id, date, content
        case authorName = "author_name"
    }
    
    struct Content: Decodable {
        let rendered: String
    }
}
