//
//  ThemeManager.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import Foundation
import Combine
import SwiftUI

/// Manages Dark/Light mode preference using AppStorage.
class ThemeManager: ObservableObject {
    // AppStorage stores the user's explicit preference (true=Dark, false=Light)
    @AppStorage("isDarkModeEnabled") var isDarkModeEnabled: Bool? {
        didSet {
            // Force SwiftUI to re-read the preferredColorScheme when this value changes
            objectWillChange.send()
        }
    }

    /// Computed property to determine the current ColorScheme to apply.
    var colorScheme: ColorScheme? {
        // If nil (no preference set), let the system decide.
        guard let isEnabled = isDarkModeEnabled else { return nil }
        return isEnabled ? .dark : .light
    }

    // Initialize: If no preference is saved, force Dark Mode initially as requested.
    init() {
        if isDarkModeEnabled == nil {
            isDarkModeEnabled = true // Default to Dark Mode
        }
    }
}
