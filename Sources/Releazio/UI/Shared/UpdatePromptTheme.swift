//
//  UpdatePromptTheme.swift
//  Releazio
//
//  Created by Releazio Team on 05.10.2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Update prompt style
public enum UpdatePromptStyle {
    case native
    
    /// Default style
    public static let `default`: UpdatePromptStyle = .native
}

/// Theme configuration for update prompt
public struct UpdatePromptTheme {
    
    // MARK: - Style
    
    public let style: UpdatePromptStyle
    
    // MARK: - Colors (Light/Dark aware)
    
    /// Background color
    public var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(white: 0.0)
        default:
            return Color(white: 1.0)
        }
    }
    
    /// Header background color
    public var headerBackgroundColor: Color {
        return colorScheme == .dark ? Color(white: 0.0) : Color(white: 1.0)
    }
    
    /// Header text color
    public var headerTextColor: Color {
        return .primary
    }
    
    /// Primary button color
    public var primaryButtonColor: Color {
        switch colorScheme {
        case .dark:
            return Color(white: 0.2) // Светло-серый для темной темы
        default:
            return .black
        }
    }
    
    /// Primary button text color
    public var primaryButtonTextColor: Color {
        return .white // Всегда белый текст
    }
    
    /// Link color (for "Что нового")
    public var linkColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.3, green: 0.5, blue: 1.0)
        default:
            return .blue
        }
    }
    
    /// Text color
    public var textColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .black
        }
    }
    
    /// Secondary text color
    public var secondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(white: 0.7)
        default:
            return .secondary
        }
    }
    
    /// Overlay color
    public var overlayColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.6)
        default:
            return Color.black.opacity(0.4)
        }
    }
    
    /// Close button color
    public var closeButtonColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .gray
        }
    }
    
    // MARK: - Properties
    
    public let colorScheme: ColorScheme
    
    // MARK: - Initialization
    
    /// Initialize theme
    /// - Parameters:
    ///   - style: Update prompt style (Native)
    ///   - colorScheme: Color scheme (light or dark)
    public init(style: UpdatePromptStyle = .default, colorScheme: ColorScheme = .light) {
        self.style = style
        self.colorScheme = colorScheme
    }
    
    // MARK: - Factory Methods
    
    /// Native light theme
    public static var nativeLight: UpdatePromptTheme {
        return UpdatePromptTheme(style: .native, colorScheme: .light)
    }
    
    /// Native dark theme
    public static var nativeDark: UpdatePromptTheme {
        return UpdatePromptTheme(style: .native, colorScheme: .dark)
    }
}

#if canImport(UIKit) && !os(macOS)

/// UIKit theme for update prompt
public struct UpdatePromptUIKitTheme {
    
    public let style: UpdatePromptStyle
    
    public var backgroundColor: UIColor {
        return .systemBackground
    }
    
    public var headerBackgroundColor: UIColor {
        return .systemBackground
    }
    
    public var headerTextColor: UIColor {
        return .label
    }
    
    public var primaryButtonColor: UIColor {
        switch colorScheme {
        case .dark:
            return UIColor(white: 0.2, alpha: 1.0) // Светло-серый для темной темы
        default:
            return .black
        }
    }
    
    public var primaryButtonTextColor: UIColor {
        return .white // Всегда белый текст
    }
    
    public var linkColor: UIColor {
        switch colorScheme {
        case .dark:
            return UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
        default:
            return .systemBlue
        }
    }
    
    public var textColor: UIColor {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .black
        }
    }
    
    public var secondaryTextColor: UIColor {
        switch colorScheme {
        case .dark:
            return UIColor(white: 0.7, alpha: 1.0)
        default:
            return .secondaryLabel
        }
    }
    
    public var overlayColor: UIColor {
        switch colorScheme {
        case .dark:
            return UIColor.black.withAlphaComponent(0.6)
        default:
            return UIColor.black.withAlphaComponent(0.4)
        }
    }
    
    public var closeButtonColor: UIColor {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .gray
        }
    }
    
    public let colorScheme: UIUserInterfaceStyle
    
    public init(style: UpdatePromptStyle = .default, colorScheme: UIUserInterfaceStyle = .light) {
        self.style = style
        self.colorScheme = colorScheme
    }
    
    public static var nativeLight: UpdatePromptUIKitTheme {
        return UpdatePromptUIKitTheme(style: .native, colorScheme: .light)
    }
    
    public static var nativeDark: UpdatePromptUIKitTheme {
        return UpdatePromptUIKitTheme(style: .native, colorScheme: .dark)
    }
}

#endif

