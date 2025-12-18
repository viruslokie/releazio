//
//  VersionView.swift
//  Releazio
//
//  Created by Releazio Team on 05.10.2025.
//

import SwiftUI

/// SwiftUI view for displaying app version with update button
/// Displays version string and optional update button if update is available
public struct VersionView: View {
    
    // MARK: - Properties
    
    /// Current version string
    public let version: String
    
    /// Whether update is available
    public let isUpdateAvailable: Bool
    
    /// Update button action
    public let onUpdateTap: (() -> Void)?
    
    /// Version tap action (opens post URL)
    public let onVersionTap: (() -> Void)?
    
    /// Badge URL (post_url or posts_url) for version tap
    private let badgeURL: String?
    
    /// Post URL from channel data
    private let postUrl: String?
    
    /// Posts URL (list of posts) from channel data
    private let postsUrl: String?
    
    /// Whether to show badge (from UpdateState)
    private let shouldShowBadge: Bool
    
    /// UpdateState for checking post opened status
    private let updateState: UpdateState?
    
    /// Custom colors for component
    private let customColors: UIComponentColors?
    
    /// Custom localization strings
    private let customStrings: UILocalizationStrings?
    
    /// Localization manager (with auto-detected locale)
    private let localization: LocalizationManager
    
    /// Color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    /// State to track if post is opened (for UI updates)
    @State private var isPostOpenedState: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize version view with UpdateState
    /// - Parameters:
    ///   - updateState: Update state from checkUpdates()
    ///   - customColors: Custom colors for buttons and text (optional)
    ///   - customStrings: Custom localization strings (optional)
    ///   - onUpdateTap: Action when update button is tapped
    ///   - onVersionTap: Action when version text is tapped (optional, defaults to opening badgeURL)
    public init(
        updateState: UpdateState,
        customColors: UIComponentColors? = nil,
        customStrings: UILocalizationStrings? = nil,
        onUpdateTap: (() -> Void)? = nil,
        onVersionTap: (() -> Void)? = nil
    ) {
        // Use version name for display (e.g., "1.2.3" instead of build number)
        self.version = updateState.currentVersionName
        // Show update button if update is available (for all types, not just type 1)
        // This is for the bottom component which should show update button whenever there's an update
        self.isUpdateAvailable = updateState.isUpdateAvailable
        self.badgeURL = updateState.badgeURL
        self.postUrl = updateState.channelData.postUrl
        self.postsUrl = updateState.channelData.postsUrl
        self.shouldShowBadge = updateState.shouldShowBadge
        self.updateState = updateState
        self.customColors = customColors
        self.customStrings = customStrings
        // Auto-detect locale from system
        let detectedLocale = LocalizationManager.detectSystemLocale()
        self.localization = LocalizationManager(locale: detectedLocale)
        self.onUpdateTap = onUpdateTap
        self.onVersionTap = onVersionTap
        // Initialize state based on post opened status
        let initialPostOpened = updateState.channelData.postUrl != nil ? Releazio.shared.isPostOpened(postURL: updateState.channelData.postUrl!) : false
        self._isPostOpenedState = State(initialValue: initialPostOpened)
    }
    
    /// Initialize version view
    /// - Parameters:
    ///   - version: Current app version string
    ///   - isUpdateAvailable: Whether update is available
    ///   - customColors: Custom colors for buttons and text (optional)
    ///   - customStrings: Custom localization strings (optional)
    ///   - onUpdateTap: Action when update button is tapped
    ///   - onVersionTap: Action when version text is tapped (optional)
    public init(
        version: String,
        isUpdateAvailable: Bool = false,
        customColors: UIComponentColors? = nil,
        customStrings: UILocalizationStrings? = nil,
        onUpdateTap: (() -> Void)? = nil,
        onVersionTap: (() -> Void)? = nil
    ) {
        self.version = version
        self.isUpdateAvailable = isUpdateAvailable
        self.badgeURL = nil
        self.postUrl = nil
        self.postsUrl = nil
        self.shouldShowBadge = false
        self.updateState = nil
        self.customColors = customColors
        self.customStrings = customStrings
        // Auto-detect locale from system
        let detectedLocale = LocalizationManager.detectSystemLocale()
        self.localization = LocalizationManager(locale: detectedLocale)
        self.onUpdateTap = onUpdateTap
        self.onVersionTap = onVersionTap
        self._isPostOpenedState = State(initialValue: false)
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 12) {
            // Version label (tappable) with yellow dot on the left
            Button(action: {
                handleVersionTap()
            }) {
                HStack(spacing: 6) {
                    // Yellow dot (when post is unread) - on the left
                    if shouldShowYellowDot {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(localizedVersionText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(versionBackgroundColor)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Update button (if available)
            if isUpdateAvailable {
                Button(action: {
                    onUpdateTap?()
                }) {
                    Text(updateButtonText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(updateButtonTextColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(updateButtonColor)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var localizedVersionText: String {
        // Format: "Version {version}" or "Версия {version}"
        let versionLabelText = customStrings?.versionText ?? localization.versionText
        return "\(versionLabelText) \(version)"
    }
    
    private var versionBackgroundColor: Color {
        if let customColor = customColors?.versionBackgroundColor {
            #if canImport(UIKit)
            return Color(customColor)
            #else
            return customColor
            #endif
        }
        switch colorScheme {
        case .dark:
            return Color(white: 0.2)
        default:
            return Color(white: 0.95)
        }
    }
    
    private var textColor: Color {
        if let customColor = customColors?.versionTextColor {
            #if canImport(UIKit)
            return Color(customColor)
            #else
            return customColor
            #endif
        }
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .black
        }
    }
    
    private var updateButtonColor: Color {
        if let customColor = customColors?.updateButtonColor {
            #if canImport(UIKit)
            return Color(customColor)
            #else
            return customColor
            #endif
        }
        // Default black button
        return .black
    }
    
    private var updateButtonTextColor: Color {
        if let customColor = customColors?.updateButtonTextColor {
            #if canImport(UIKit)
            return Color(customColor)
            #else
            return customColor
            #endif
        }
        // Default white text on black button
        return .white
    }
    
    /// Whether to show yellow dot (post is unread)
    private var shouldShowYellowDot: Bool {
        // Show dot if postUrl exists and post is not opened
        // This works for all update types, not just type 0
        guard let postUrl = postUrl else {
            return false
        }
        
        // Use state variable for UI updates, but also check storage for initial state
        return !isPostOpenedState
    }
    
    /// Handle version tap - open post URL if yellow dot is visible, otherwise open posts_url (list of posts)
    private func handleVersionTap() {
        if let customHandler = onVersionTap {
            customHandler()
        } else if shouldShowYellowDot, let postUrl = postUrl, let url = URL(string: postUrl) {
            // If yellow dot is visible, open post URL (single post)
            #if canImport(UIKit)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                // Mark post as opened after opening
                Releazio.shared.markPostAsOpened(postURL: postUrl)
                // Update state to hide yellow dot immediately
                isPostOpenedState = true
            }
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            Releazio.shared.markPostAsOpened(postURL: postUrl)
            // Update state to hide yellow dot immediately
            isPostOpenedState = true
            #endif
        } else if let postsUrl = postsUrl, let url = URL(string: postsUrl) {
            // If no yellow dot, open posts_url (list of posts) - ВНИМАНИЕ: posts_url с S в конце!
            #if canImport(UIKit)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
    
    private var updateButtonText: String {
        return customStrings?.updateButtonText ?? localization.updateButtonText
    }
}

