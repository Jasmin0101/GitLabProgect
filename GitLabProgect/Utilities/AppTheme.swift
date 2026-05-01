import SwiftUI

enum AppTheme {
    enum Palette {
        static let darkBackground = Color(red: 24 / 255, green: 23 / 255, blue: 28 / 255) // #18171c
        static let darkSurface = Color(red: 51 / 255, green: 50 / 255, blue: 59 / 255)    // #33323b
        static let darkSecondarySurface = Color(red: 66 / 255, green: 65 / 255, blue: 76 / 255)
    }

    enum Overlay {
        static let darkTop = Palette.darkBackground.opacity(0.70)
        static let darkBottom = Palette.darkBackground.opacity(0.92)
    }
}
