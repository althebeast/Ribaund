//
//  Category.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//

import Foundation

// Represents a single Category from the API
struct Category: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}
