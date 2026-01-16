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
        // Show update button if update is available (for all types, not just type 1)
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
        
        print("🔵 [VersionUIKitView] init called")
        print("   - layoutStyle: \(layoutStyle)")
        print("   - buttonConfiguration: width=\(buttonConfiguration?.width?.description ?? "nil"), height=\(self.buttonConfiguration.height), cornerRadius=\(self.buttonConfiguration.cornerRadius), spacing=\(self.buttonConfiguration.spacing)")
        print("   - frame: \(frame)")
        print("   - isUpdateAvailable: \(isUpdateAvailable)")
        
        setupUI(version: version, isUpdateAvailable: isUpdateAvailable)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(version: String, isUpdateAvailable: Bool) {
        // Yellow dot (for unread post)
        yellowDotView.backgroundColor = .systemYellow
        yellowDotView.layer.cornerRadius = 4
        yellowDotView.translatesAutoresizingMaskIntoConstraints = false
        yellowDotView.isHidden = !shouldShowYellowDot
        
        // Version label (tappable)
        let versionText = customStrings?.versionText ?? localization.versionText
        versionLabel.text = "\(versionText) \(version)"
        versionLabel.font = .systemFont(ofSize: 15, weight: .medium)
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.isUserInteractionEnabled = true
        versionLabel.layer.cornerRadius = 10
        versionLabel.clipsToBounds = true
        
        // Add tap gesture to version label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(versionLabelTapped))
        versionLabel.addGestureRecognizer(tapGesture)
        
        // Update button
        let buttonText = customStrings?.updateButtonText ?? localization.updateButtonText
        updateButton.setTitle(buttonText, for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        updateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        updateButton.titleLabel?.minimumScaleFactor = 0.7
        updateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        // Corner radius will be set in setupConstraints based on layout style
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.isHidden = !isUpdateAvailable
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        
        print("🟢 [VersionUIKitView] setupUI completed")
        print("   - buttonText: '\(buttonText)'")
        print("   - buttonFont: \(updateButton.titleLabel?.font?.pointSize ?? 0)pt")
        print("   - contentEdgeInsets: \(updateButton.contentEdgeInsets)")
        print("   - button.isHidden: \(updateButton.isHidden)")
        print("   - button.intrinsicContentSize: \(updateButton.intrinsicContentSize)")
        
        addSubview(yellowDotView)
        addSubview(versionLabel)
        addSubview(updateButton)
    }
    
    private var versionLabelLeadingConstraint: NSLayoutConstraint!
    
    private func setupConstraints() {
        // Yellow dot
        yellowDotView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        yellowDotView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        yellowDotView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        
        // Version label - use dynamic constraint for leading
        versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        versionLabelLeadingConstraint.isActive = true
        
        // If button has fixed width, ensure self has minimum width to accommodate it
        if layoutStyle == .vertical, let fixedButtonWidth = buttonConfiguration.width {
            // Set minimum width for self to accommodate fixed-width button
            let minWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: fixedButtonWidth)
            minWidthConstraint.priority = .required
            minWidthConstraint.isActive = true
            print("   ✅ Self min width constraint set: \(fixedButtonWidth)pt (to accommodate fixed-width button)")
        }
        
        if layoutStyle == .vertical {
            print("🟡 [VersionUIKitView] setupConstraints: VERTICAL layout")
            print("   - buttonConfiguration.height: \(buttonConfiguration.height)")
            print("   - buttonConfiguration.width: \(buttonConfiguration.width?.description ?? "nil")")
            print("   - buttonConfiguration.spacing: \(buttonConfiguration.spacing)")
            print("   - buttonConfiguration.cornerRadius: \(buttonConfiguration.cornerRadius)")
            
            // Vertical layout: version on top, button below
            yellowDotView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
            yellowDotView.centerYAnchor.constraint(equalTo: versionLabel.centerYAnchor).isActive = true
            
            versionLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            versionLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            versionLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            // Update button below version - using buttonConfiguration
            updateButton.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: buttonConfiguration.spacing).isActive = true
            
            // Fixed height constraint with high priority
            let heightConstraint = updateButton.heightAnchor.constraint(equalToConstant: buttonConfiguration.height)
            heightConstraint.priority = .required
            heightConstraint.isActive = true
            print("   ✅ Height constraint set: \(buttonConfiguration.height)pt, priority: \(heightConstraint.priority.rawValue)")
            
            // Bottom anchor with lower priority (only if view needs to stretch)
            let bottomConstraint = updateButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            bottomConstraint.priority = .defaultLow
            bottomConstraint.isActive = true
            print("   ✅ Bottom constraint set: lessThanOrEqualTo bottomAnchor, priority: \(bottomConstraint.priority.rawValue)")
            
            // Center button horizontally
            updateButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            // Prevent button from stretching vertically - enforce fixed height
            updateButton.setContentHuggingPriority(.required, for: .vertical)
            updateButton.setContentCompressionResistancePriority(.required, for: .vertical)
            print("   ✅ ContentHuggingPriority (vertical): \(updateButton.contentHuggingPriority(for: .vertical).rawValue)")
            print("   ✅ ContentCompressionResistancePriority (vertical): \(updateButton.contentCompressionResistancePriority(for: .vertical).rawValue)")
            
            // Width configuration
            if let fixedWidth = buttonConfiguration.width {
                // Fixed width: use exact width specified
                updateButton.widthAnchor.constraint(equalToConstant: fixedWidth).isActive = true
                print("   ✅ Fixed width constraint set: \(fixedWidth)pt")
            } else {
                // Adaptive width: size to fit content (text + padding)
                // Use intrinsic content size - button will size based on its text
                updateButton.setContentHuggingPriority(.required, for: .horizontal)
                updateButton.setContentCompressionResistancePriority(.required, for: .horizontal)
                print("   ✅ Adaptive width: using intrinsic content size")
            }
            
            updateButton.layer.cornerRadius = buttonConfiguration.cornerRadius
            print("   ✅ Corner radius set: \(buttonConfiguration.cornerRadius)")
        } else {
            // Horizontal layout: version on left, button on right (original)
            yellowDotView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            versionLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            versionLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            versionLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            // Update button on the right - using buttonConfiguration
            updateButton.leadingAnchor.constraint(equalTo: versionLabel.trailingAnchor, constant: buttonConfiguration.spacing).isActive = true
            updateButton.centerYAnchor.constraint(equalTo: versionLabel.centerYAnchor).isActive = true
            updateButton.heightAnchor.constraint(equalToConstant: buttonConfiguration.height).isActive = true
            
            if let width = buttonConfiguration.width {
                // Fixed width
                updateButton.widthAnchor.constraint(equalToConstant: width).isActive = true
            } else {
                // Fill to trailing
                updateButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
            
            updateButton.layer.cornerRadius = buttonConfiguration.cornerRadius
        }
        
        updateConstraintsForYellowDot()

        // Colors call also updates yellow dot constraints. It must run after constraints are created.
        updateColors()
        
        print("🟣 [VersionUIKitView] setupConstraints completed")
        print("   - All constraints installed")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        print("🔴 [VersionUIKitView] layoutSubviews called")
        print("   - self.frame: \(frame)")
        print("   - self.bounds: \(bounds)")
        print("   - updateButton.frame: \(updateButton.frame)")
        print("   - updateButton.bounds: \(updateButton.bounds)")
        print("   - updateButton.intrinsicContentSize: \(updateButton.intrinsicContentSize)")
        
        // Check all height-related constraints
        let heightConstraints = updateButton.constraints.filter { $0.firstAttribute == .height }
        print("   - updateButton height constraints count: \(heightConstraints.count)")
        for (index, constraint) in heightConstraints.enumerated() {
            print("     [\(index)] height constraint: constant=\(constraint.constant), priority=\(constraint.priority.rawValue), isActive=\(constraint.isActive)")
        }
        
        // Check if button has conflicting constraints
        let allConstraints = updateButton.constraints + constraints.filter { $0.firstItem === updateButton || $0.secondItem === updateButton }
        let conflictingConstraints = allConstraints.filter { !$0.isActive }
        if !conflictingConstraints.isEmpty {
            print("   ⚠️ Found \(conflictingConstraints.count) inactive constraints on updateButton")
        }
        
        // Check all width-related constraints
        let widthConstraints = updateButton.constraints.filter { $0.firstAttribute == .width }
        print("   - updateButton width constraints count: \(widthConstraints.count)")
        for (index, constraint) in widthConstraints.enumerated() {
            print("     [\(index)] width constraint: constant=\(constraint.constant), priority=\(constraint.priority.rawValue), isActive=\(constraint.isActive), relation=\(constraint.relation.rawValue)")
        }
        
        // Check self width constraints
        let selfWidthConstraints = constraints.filter { $0.firstAttribute == .width && ($0.firstItem === self || $0.secondItem === self) }
        print("   - self width constraints count: \(selfWidthConstraints.count)")
        for (index, constraint) in selfWidthConstraints.enumerated() {
            print("     [\(index)] self width constraint: constant=\(constraint.constant), priority=\(constraint.priority.rawValue), isActive=\(constraint.isActive)")
        }
        
        print("   - versionLabel.frame: \(versionLabel.frame)")
        print("   - Expected button height: \(buttonConfiguration.height)pt")
        print("   - Actual button height: \(updateButton.frame.height)pt")
        if abs(updateButton.frame.height - buttonConfiguration.height) > 0.1 {
            print("   ❌ HEIGHT MISMATCH! Expected: \(buttonConfiguration.height)pt, Actual: \(updateButton.frame.height)pt")
        } else {
            print("   ✅ Height matches configuration")
        }
        
        print("   - Expected button width: \(buttonConfiguration.width?.description ?? "adaptive")pt")
        print("   - Actual button width: \(updateButton.frame.width)pt")
        if let expectedWidth = buttonConfiguration.width {
            if abs(updateButton.frame.width - expectedWidth) > 0.1 {
                print("   ❌ WIDTH MISMATCH! Expected: \(expectedWidth)pt, Actual: \(updateButton.frame.width)pt")
            } else {
                print("   ✅ Width matches configuration")
            }
        }
        
        print("   - self.width: \(frame.width)pt, button.width: \(updateButton.frame.width)pt")
        if frame.width < updateButton.frame.width {
            print("   ⚠️ WARNING: self width (\(frame.width)pt) is LESS than button width (\(updateButton.frame.width)pt)! Button will overflow.")
        }
        
        // Update corner radius based on actual button size
        // For full rounding (pill shape), maximum corner radius is min(height, width) / 2
        // This ensures corner radius is always appropriate for the button size
        let actualHeight = updateButton.frame.height
        let actualWidth = updateButton.frame.width
        let maxCornerRadius = min(actualHeight, actualWidth) / 2
        
        // Use the smaller value: either from configuration or calculated maximum
        // If config specifies a smaller value, use it (partial rounding)
        // If config specifies a larger value, cap at maxCornerRadius (full rounding)
        let finalCornerRadius = min(buttonConfiguration.cornerRadius, maxCornerRadius)
        
        if abs(updateButton.layer.cornerRadius - finalCornerRadius) > 0.1 {
            updateButton.layer.cornerRadius = finalCornerRadius
            print("   🔄 Corner radius updated: \(finalCornerRadius)pt (max: \(maxCornerRadius)pt, config: \(buttonConfiguration.cornerRadius)pt)")
        } else {
            print("   ✅ Corner radius: \(updateButton.layer.cornerRadius)pt (max: \(maxCornerRadius)pt, config: \(buttonConfiguration.cornerRadius)pt)")
        }
    }
    
    private func updateConstraintsForYellowDot() {
        guard versionLabelLeadingConstraint != nil else { return }
        versionLabelLeadingConstraint.isActive = false
        if shouldShowYellowDot {
            versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(equalTo: yellowDotView.trailingAnchor, constant: 12)
        } else {
            versionLabelLeadingConstraint = versionLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        }
        versionLabelLeadingConstraint.isActive = true
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            print("🟠 [VersionUIKitView] didMoveToSuperview: view added to hierarchy")
            print("   - superview: \(type(of: superview!))")
            print("   - self.frame: \(frame)")
            print("   - updateButton.frame: \(updateButton.frame)")
        }
    }
    
    private func updateColors() {
        print("🟤 [VersionUIKitView] updateColors called")
        // Version label background
        if transparentVersionBackground {
            versionLabel.backgroundColor = .clear
        } else if let customColor = customColors?.versionBackgroundColor {
            versionLabel.backgroundColor = customColor
        } else {
            switch colorScheme {
            case .dark:
                versionLabel.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            default:
                versionLabel.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            }
        }
        
        // Version label text color
        if let customColor = customColors?.versionTextColor {
            versionLabel.textColor = customColor
        } else {
            switch colorScheme {
            case .dark:
                versionLabel.textColor = .white
            default:
                versionLabel.textColor = .black
            }
        }
        
        // Update button background
        if let customColor = customColors?.updateButtonColor {
            updateButton.backgroundColor = customColor
        } else {
            // Default black button
            updateButton.backgroundColor = .black
        }
        
        // Update button text color
        if let customColor = customColors?.updateButtonTextColor {
            updateButton.setTitleColor(customColor, for: .normal)
        } else {
            // Default white text on black button
            updateButton.setTitleColor(.white, for: .normal)
        }
        
        // Update yellow dot visibility and constraints
        yellowDotView.isHidden = !shouldShowYellowDot
        updateConstraintsForYellowDot()
        
        print("   - updateButton.backgroundColor: \(updateButton.backgroundColor?.description ?? "nil")")
        print("   - updateButton.titleColor: \(updateButton.titleColor(for: .normal)?.description ?? "nil")")
        print("   - updateButton.frame after colors: \(updateButton.frame)")
        print("🟤 [VersionUIKitView] updateColors completed")
    }
    
    /// Whether to show yellow dot (post is unread)
    private var shouldShowYellowDot: Bool {
        // Show dot if postUrl exists and badgeURL equals postUrl (post not read)
        return postUrl != nil && badgeURL == postUrl
    }
    
    // MARK: - Public Methods
    
    /// Update version and update availability
    /// - Parameters:
    ///   - version: Version string
    ///   - isUpdateAvailable: Whether update is available
    public func update(version: String, isUpdateAvailable: Bool) {
        let versionText = customStrings?.versionText ?? localization.versionText
        versionLabel.text = "\(versionText) \(version)"
        updateButton.isHidden = !isUpdateAvailable
    }
    
    /// Update from UpdateState
    /// - Parameter updateState: Update state from checkUpdates()
    public func update(updateState: UpdateState) {
        // Show update button if update is available (for all types)
        self.badgeURL = updateState.badgeURL
        self.postUrl = updateState.channelData.postUrl
        update(version: updateState.currentVersionName, isUpdateAvailable: updateState.isUpdateAvailable)
        updateColors() // Update yellow dot visibility
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

