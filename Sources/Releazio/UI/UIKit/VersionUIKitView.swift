//
//  VersionView.swift
//  Releazio
//
//  Created by Releazio Team on 05.10.2025.
//

#if canImport(UIKit)
import UIKit

/// Layout style for version view
public enum LayoutStyle {
    case horizontal  // Version on left, button on right (default)
    case vertical    // Version on top, button below
}

/// Configuration for update button appearance and layout
public struct UpdateButtonConfiguration {
    /// Button width (nil means fill available space)
    public let width: CGFloat?
    
    /// Button height
    public let height: CGFloat
    
    /// Corner radius
    public let cornerRadius: CGFloat
    
    /// Spacing from version label
    public let spacing: CGFloat
    
    /// Initializer
    /// - Parameters:
    ///   - width: Button width (nil for fill, default: nil for horizontal, 55 for vertical)
    ///   - height: Button height (default: 44 for horizontal, 16 for vertical)
    ///   - cornerRadius: Corner radius (default: 10 for horizontal, 18 for vertical)
    ///   - spacing: Spacing from version label (default: 12 for horizontal, 8 for vertical)
    public init(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat,
        spacing: CGFloat
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.spacing = spacing
    }
    
    /// Default configuration for horizontal layout
    public static let horizontalDefault = UpdateButtonConfiguration(
        width: nil,  // Fill from versionLabel.trailing to trailing
        height: 44,
        cornerRadius: 10,
        spacing: 12
    )
    
    /// Default configuration for vertical layout
    public static let verticalDefault = UpdateButtonConfiguration(
        width: 55,
        height: 16,
        cornerRadius: 18,
        spacing: 8
    )
}

/// UIKit view for displaying app version with update button
/// Displays version string and optional update button if update is available
public class VersionUIKitView: UIView {
    
    // MARK: - Properties
    
    /// Yellow dot view (for unread post)
    private let yellowDotView: UIView
    
    /// Version label
    private let versionLabel: UILabel
    
    /// Update button
    private let updateButton: UIButton
    
    /// Badge URL (post_url or posts_url) for version tap
    private var badgeURL: String?
    
    /// Post URL from channel data
    private var postUrl: String?
    
    /// Custom colors for component
    private let customColors: UIComponentColors?
    
    /// Custom localization strings
    private let customStrings: UILocalizationStrings?
    
    /// Localization manager (with auto-detected locale)
    private let localization: LocalizationManager
    
    /// Layout style (horizontal or vertical)
    private let layoutStyle: LayoutStyle
    
    /// Whether version background should be transparent
    private let transparentVersionBackground: Bool
    
    /// Update button configuration
    private let buttonConfiguration: UpdateButtonConfiguration
    
    /// Update button action
    public var onUpdateTap: (() -> Void)?
    
    /// Version tap action (opens post URL)
    public var onVersionTap: (() -> Void)?
    
    /// Color scheme
    public var colorScheme: UIUserInterfaceStyle = .light {
        didSet {
            updateColors()
        }
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let versionFontSize: CGFloat = 13
        static let versionFontWeight: UIFont.Weight = .regular
        static let versionLineSpacing: CGFloat = 8.0
        static let versionCornerRadius: CGFloat = 10
        static let yellowDotSize: CGFloat = 8
        static let yellowDotCornerRadius: CGFloat = 4
        static let yellowDotSpacing: CGFloat = 12
        static let yellowDotTopOffset: CGFloat = 8
        static let yellowDotVerticalOffset: CGFloat = 6.5 // ~half of 13pt font
        static let buttonFontSize: CGFloat = 15
        static let buttonFontWeight: UIFont.Weight = .semibold
        static let buttonMinScaleFactor: CGFloat = 0.7
        static let buttonContentInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        static let horizontalVersionLabelHeight: CGFloat = 44
    }
    
    // MARK: - Initialization
    
    /// Initialize version view with UpdateState
    /// - Parameters:
    ///   - updateState: Update state from checkUpdates()
    ///   - customColors: Custom colors for buttons and text (optional)
    ///   - customStrings: Custom localization strings (optional)
    ///   - layoutStyle: Layout style (horizontal or vertical, default: .horizontal)
    ///   - transparentVersionBackground: Whether version background should be transparent (default: false)
    ///   - buttonConfiguration: Update button configuration (default: based on layoutStyle)
    ///   - frame: View frame
    public convenience init(
        updateState: UpdateState,
        customColors: UIComponentColors? = nil,
        customStrings: UILocalizationStrings? = nil,
        layoutStyle: LayoutStyle = .horizontal,
        transparentVersionBackground: Bool = false,
        buttonConfiguration: UpdateButtonConfiguration? = nil,
        frame: CGRect = .zero
    ) {
        self.init(
            version: updateState.currentVersionName,
            isUpdateAvailable: updateState.isUpdateAvailable,
            badgeURL: updateState.badgeURL,
            postUrl: updateState.channelData.postUrl,
            customColors: customColors,
            customStrings: customStrings,
            layoutStyle: layoutStyle,
            transparentVersionBackground: transparentVersionBackground,
            buttonConfiguration: buttonConfiguration,
            frame: frame
        )
    }
    
    /// Initialize version view
    /// - Parameters:
    ///   - version: Current app version string
    ///   - isUpdateAvailable: Whether update is available
    ///   - badgeURL: Badge URL for version tap (optional)
    ///   - postUrl: Post URL from channel data (optional)
    ///   - customColors: Custom colors for buttons and text (optional)
    ///   - customStrings: Custom localization strings (optional)
    ///   - layoutStyle: Layout style (horizontal or vertical, default: .horizontal)
    ///   - transparentVersionBackground: Whether version background should be transparent (default: false)
    ///   - buttonConfiguration: Update button configuration (default: based on layoutStyle)
    ///   - frame: View frame
    public init(
        version: String,
        isUpdateAvailable: Bool = false,
        badgeURL: String? = nil,
        postUrl: String? = nil,
        customColors: UIComponentColors? = nil,
        customStrings: UILocalizationStrings? = nil,
        layoutStyle: LayoutStyle = .horizontal,
        transparentVersionBackground: Bool = false,
        buttonConfiguration: UpdateButtonConfiguration? = nil,
        frame: CGRect = .zero
    ) {
        self.yellowDotView = UIView()
        self.versionLabel = UILabel()
        self.updateButton = UIButton(type: .system)
        self.badgeURL = badgeURL
        self.postUrl = postUrl
        self.customColors = customColors
        self.customStrings = customStrings
        self.layoutStyle = layoutStyle
        self.transparentVersionBackground = transparentVersionBackground
        // Use provided configuration or default based on layout style
        self.buttonConfiguration = buttonConfiguration ?? (layoutStyle == .vertical ? .verticalDefault : .horizontalDefault)
        // Auto-detect locale from system
        let detectedLocale = LocalizationManager.detectSystemLocale()
        self.localization = LocalizationManager(locale: detectedLocale)
        
        super.init(frame: frame)
        
        setupSubviews()
        setupVersionLabel(version: version)
        setupUpdateButton(isUpdateAvailable: isUpdateAvailable)
        setupConstraints()
        updateColors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        addSubview(yellowDotView)
        addSubview(versionLabel)
        addSubview(updateButton)
    }
    
    private func setupYellowDot() {
        yellowDotView.backgroundColor = .systemYellow
        yellowDotView.layer.cornerRadius = Constants.yellowDotCornerRadius
        yellowDotView.translatesAutoresizingMaskIntoConstraints = false
        yellowDotView.isHidden = !shouldShowYellowDot
    }
    
    private func setupVersionLabel(version: String) {
        setupYellowDot()
        
        let versionText = customStrings?.versionText ?? localization.versionText
        let font = UIFont.systemFont(ofSize: Constants.versionFontSize, weight: Constants.versionFontWeight)
        
        if version.contains("\n") {
            configureVersionLabelForTwoLines(version: version, font: font)
        } else {
            configureVersionLabelForSingleLine(version: version, versionText: versionText, font: font)
        }
        
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.isUserInteractionEnabled = true
        versionLabel.adjustsFontSizeToFitWidth = false
        
        if !transparentVersionBackground {
            versionLabel.layer.cornerRadius = Constants.versionCornerRadius
            versionLabel.clipsToBounds = true
        } else {
            versionLabel.clipsToBounds = false
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(versionLabelTapped))
        versionLabel.addGestureRecognizer(tapGesture)
    }
    
    private func configureVersionLabelForTwoLines(version: String, font: UIFont) {
        versionLabel.numberOfLines = 2
        versionLabel.lineBreakMode = .byWordWrapping
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.versionLineSpacing
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributedString = NSAttributedString(
            string: version,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.label, // Will be updated in updateColors()
                .paragraphStyle: paragraphStyle
            ]
        )
        versionLabel.attributedText = attributedString
    }
    
    private func configureVersionLabelForSingleLine(version: String, versionText: String, font: UIFont) {
        versionLabel.text = "\(versionText) \(version)"
        versionLabel.numberOfLines = 1
        versionLabel.font = font
    }
    
    private func setupUpdateButton(isUpdateAvailable: Bool) {
        let buttonText = customStrings?.updateButtonText ?? localization.updateButtonText
        updateButton.setTitle(buttonText, for: .normal)
        updateButton.titleLabel?.font = UIFont.systemFont(ofSize: Constants.buttonFontSize, weight: Constants.buttonFontWeight)
        updateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        updateButton.titleLabel?.minimumScaleFactor = Constants.buttonMinScaleFactor
        updateButton.contentEdgeInsets = Constants.buttonContentInsets
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.isHidden = !isUpdateAvailable
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Constraints
    
    private var versionLabelLeadingConstraint: NSLayoutConstraint?
    
    private func setupConstraints() {
        setupYellowDotConstraints()
        setupVersionLabelBaseConstraints()
        
        if layoutStyle == .vertical {
            setupVerticalLayoutConstraints()
        } else {
            setupHorizontalLayoutConstraints()
        }
        
        updateConstraintsForYellowDot()
    }
    
    private func setupYellowDotConstraints() {
        yellowDotView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        yellowDotView.widthAnchor.constraint(equalToConstant: Constants.yellowDotSize).isActive = true
        yellowDotView.heightAnchor.constraint(equalToConstant: Constants.yellowDotSize).isActive = true
    }
    
    private func setupVersionLabelBaseConstraints() {
        if layoutStyle == .horizontal {
            versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
            versionLabelLeadingConstraint?.isActive = true
        }
    }
    
    private func setupVerticalLayoutConstraints() {
        // Yellow dot positioning
        yellowDotView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.yellowDotTopOffset).isActive = true
        yellowDotView.centerYAnchor.constraint(equalTo: versionLabel.topAnchor, constant: Constants.yellowDotVerticalOffset).isActive = true
        
        // Version label
        versionLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        versionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let leadingConstraint = versionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
        leadingConstraint.priority = .defaultHigh
        leadingConstraint.isActive = true
        
        let trailingConstraint = versionLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        trailingConstraint.priority = .defaultHigh
        trailingConstraint.isActive = true
        
        versionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        versionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        versionLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        versionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Update button
        updateButton.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: buttonConfiguration.spacing).isActive = true
        updateButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let heightConstraint = updateButton.heightAnchor.constraint(equalToConstant: buttonConfiguration.height)
        heightConstraint.priority = .required
        heightConstraint.isActive = true
        
        let bottomConstraint = updateButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true
        
        updateButton.setContentHuggingPriority(.required, for: .vertical)
        updateButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        if let fixedWidth = buttonConfiguration.width {
            updateButton.widthAnchor.constraint(equalToConstant: fixedWidth).isActive = true
        } else {
            updateButton.setContentHuggingPriority(.required, for: .horizontal)
            updateButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        updateButton.layer.cornerRadius = buttonConfiguration.cornerRadius
        
        // Minimum width for self if button has fixed width
        if let fixedButtonWidth = buttonConfiguration.width {
            let minWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: fixedButtonWidth)
            minWidthConstraint.priority = .required
            minWidthConstraint.isActive = true
        }
    }
    
    private func setupHorizontalLayoutConstraints() {
        yellowDotView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        versionLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        versionLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        versionLabel.heightAnchor.constraint(equalToConstant: Constants.horizontalVersionLabelHeight).isActive = true
        
        updateButton.leadingAnchor.constraint(equalTo: versionLabel.trailingAnchor, constant: buttonConfiguration.spacing).isActive = true
        updateButton.centerYAnchor.constraint(equalTo: versionLabel.centerYAnchor).isActive = true
        updateButton.heightAnchor.constraint(equalToConstant: buttonConfiguration.height).isActive = true
        
        if let width = buttonConfiguration.width {
            updateButton.widthAnchor.constraint(equalToConstant: width).isActive = true
        } else {
            updateButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
        
        updateButton.layer.cornerRadius = buttonConfiguration.cornerRadius
    }
    
    private func updateConstraintsForYellowDot() {
        guard let leadingConstraint = versionLabelLeadingConstraint else { return }
        leadingConstraint.isActive = false
        
        if shouldShowYellowDot {
            versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(
                equalTo: yellowDotView.trailingAnchor,
                constant: Constants.yellowDotSpacing
            )
        } else {
            versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        }
        
        versionLabelLeadingConstraint?.isActive = true
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonCornerRadius()
    }
    
    private func updateButtonCornerRadius() {
        let actualHeight = updateButton.frame.height
        let actualWidth = updateButton.frame.width
        let maxCornerRadius = min(actualHeight, actualWidth) / 2
        let finalCornerRadius = min(buttonConfiguration.cornerRadius, maxCornerRadius)
        
        if abs(updateButton.layer.cornerRadius - finalCornerRadius) > 0.1 {
            updateButton.layer.cornerRadius = finalCornerRadius
        }
    }
    
    // MARK: - Colors
    
    private func updateColors() {
        updateVersionLabelColors()
        updateButtonColors()
        updateYellowDotVisibility()
    }
    
    private func updateVersionLabelColors() {
        // Background
        if transparentVersionBackground {
            versionLabel.backgroundColor = .clear
        } else if let customColor = customColors?.versionBackgroundColor {
            versionLabel.backgroundColor = customColor
        } else {
            versionLabel.backgroundColor = colorScheme == .dark
                ? UIColor(white: 0.2, alpha: 1.0)
                : UIColor(white: 0.95, alpha: 1.0)
        }
        
        // Text color
        let textColor = customColors?.versionTextColor ?? (colorScheme == .dark ? .white : .black)
        versionLabel.textColor = textColor
        
        // Update attributed text color if needed
        if let attributedText = versionLabel.attributedText {
            let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedText.addAttribute(
                .foregroundColor,
                value: textColor,
                range: NSRange(location: 0, length: mutableAttributedText.length)
            )
            versionLabel.attributedText = mutableAttributedText
        }
    }
    
    private func updateButtonColors() {
        updateButton.backgroundColor = customColors?.updateButtonColor ?? .black
        updateButton.setTitleColor(
            customColors?.updateButtonTextColor ?? .white,
            for: .normal
        )
    }
    
    private func updateYellowDotVisibility() {
        yellowDotView.isHidden = !shouldShowYellowDot
        updateConstraintsForYellowDot()
    }
    
    /// Whether to show yellow dot (post is unread)
    private var shouldShowYellowDot: Bool {
        return postUrl != nil && badgeURL == postUrl
    }
    
    // MARK: - Public Methods
    
    /// Update version and update availability
    /// - Parameters:
    ///   - version: Version string (can contain newline for two-line format)
    ///   - isUpdateAvailable: Whether update is available
    public func update(version: String, isUpdateAvailable: Bool) {
        let versionText = customStrings?.versionText ?? localization.versionText
        let font = UIFont.systemFont(ofSize: Constants.versionFontSize, weight: Constants.versionFontWeight)
        
        if version.contains("\n") {
            configureVersionLabelForTwoLines(version: version, font: font)
        } else {
            configureVersionLabelForSingleLine(version: version, versionText: versionText, font: font)
        }
        
        updateButton.isHidden = !isUpdateAvailable
        updateColors()
    }
    
    /// Update from UpdateState
    /// - Parameter updateState: Update state from checkUpdates()
    public func update(updateState: UpdateState) {
        badgeURL = updateState.badgeURL
        postUrl = updateState.channelData.postUrl
        update(version: updateState.currentVersionName, isUpdateAvailable: updateState.isUpdateAvailable)
    }
    
    // MARK: - Actions
    
    @objc private func updateButtonTapped() {
        onUpdateTap?()
    }
    
    @objc private func versionLabelTapped() {
        if let customHandler = onVersionTap {
            customHandler()
        } else if let urlString = badgeURL, let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#endif
