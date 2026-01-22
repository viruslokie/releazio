//
//  ReleazioUpdatePromptViewController.swift
//  Releazio
//
//  Created by Releazio Team on 05.10.2025.
//

#if canImport(UIKit)
import UIKit

/// UIKit view controller for Releazio update prompt
/// Supports update types 2 (popup) and 3 (popup force)
public class ReleazioUpdatePromptViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Layout {
        static let overlayAlpha: CGFloat = 0.4
        static let containerHorizontalMargin: CGFloat = 20
        static let containerCornerRadius: CGFloat = 16
        static let containerShadowRadius: CGFloat = 10
        static let containerShadowOpacity: Float = 0.2
        static let containerShadowOffset = CGSize(width: 0, height: 5)
        
        static let headerTopMargin: CGFloat = 20
        static let headerButtonSize: CGFloat = 32
        static let headerButtonHorizontalMargin: CGFloat = 16
        static let headerButtonToTitleSpacing: CGFloat = 8
        
        static let titleToMessageSpacing: CGFloat = 16
        static let messageToButtonSpacing: CGFloat = 24
        static let buttonSpacing: CGFloat = 12
        static let bottomMargin: CGFloat = 16
        
        static let contentHorizontalPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let skipButtonHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 12
    }
    
    // MARK: - Properties
    
    /// Update state from checkUpdates()
    public let updateState: UpdateState
    
    /// Update prompt style
    public let style: UpdatePromptStyle
    
    /// Theme configuration
    private var theme: UpdatePromptUIKitTheme
    
    /// Custom colors for component
    private let customColors: UIComponentColors?
    
    /// Custom localization strings
    private let customStrings: UILocalizationStrings?
    
    /// Localization manager (with auto-detected locale)
    private let localization: LocalizationManager
    
    /// Callback when user chooses to update
    public var onUpdate: (() -> Void)?
    
    /// Callback when user skips (type 3 only)
    public var onSkip: ((Int) -> Void)?
    
    /// Callback when user closes (type 2 only)
    public var onClose: (() -> Void)?
    
    /// Callback when user taps info button
    public var onInfoTap: (() -> Void)?
    
    private var remainingSkipAttempts: Int
    
    // MARK: - UI Components
    
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = resolveContainerBackgroundColor()
        view.layer.cornerRadius = Layout.containerCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = Layout.containerShadowRadius
        view.layer.shadowOpacity = Layout.containerShadowOpacity
        view.layer.shadowOffset = Layout.containerShadowOffset
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "info.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.accessibilityLabel = "Info"
        return button
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.accessibilityLabel = "Close"
        return button
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private lazy var updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }()
    
    private var activeConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    
    /// Initialize update prompt view controller
    /// - Parameters:
    ///   - updateState: Update state from checkUpdates()
    ///   - style: Update prompt style (default: .native)
    ///   - customColors: Custom colors for buttons and text (optional)
    ///   - customStrings: Custom localization strings (optional)
    ///   - onUpdate: Update action
    ///   - onSkip: Skip action (for type 3)
    ///   - onClose: Close action (for type 2)
    ///   - onInfoTap: Info button action (opens post_url)
    public init(
        updateState: UpdateState,
        style: UpdatePromptStyle = .default,
        customColors: UIComponentColors? = nil,
        customStrings: UILocalizationStrings? = nil,
        onUpdate: (() -> Void)? = nil,
        onSkip: ((Int) -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onInfoTap: (() -> Void)? = nil
    ) {
        self.updateState = updateState
        self.style = style
        self.theme = UpdatePromptUIKitTheme(style: style, colorScheme: .light)
        self.customColors = customColors
        self.customStrings = customStrings
        
        let detectedLocale = LocalizationManager.detectSystemLocale()
        self.localization = LocalizationManager(locale: detectedLocale)
        
        self.onUpdate = onUpdate
        self.onSkip = onSkip
        self.onClose = onClose
        self.onInfoTap = onInfoTap
        self.remainingSkipAttempts = updateState.remainingSkipAttempts
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        // Type 3 cannot be dismissed by user
        if updateState.updateType == 3 {
            isModalInPresentation = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        updateThemeForCurrentTraitCollection()
        setupViews()
        setupGestures()
        configureContent()
        setupConstraints()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateThemeForCurrentTraitCollection()
            updateColors()
        }
    }
    
    // MARK: - Setup
    
    private func updateThemeForCurrentTraitCollection() {
        let colorScheme = traitCollection.userInterfaceStyle
        theme = UpdatePromptUIKitTheme(style: style, colorScheme: colorScheme)
    }
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        // Add overlay
        view.addSubview(overlayView)
        
        // Add container
        view.addSubview(containerView)
        
        // Add header buttons
        if shouldShowInfoButton {
            containerView.addSubview(infoButton)
        }
        
        if shouldShowCloseButton {
            containerView.addSubview(closeButton)
        }
        
        // Add title
        containerView.addSubview(titleLabel)
        
        // Add message
        containerView.addSubview(messageLabel)
        
        // Add update button
        containerView.addSubview(updateButton)
        
        // Add skip button if needed
        if shouldShowSkipButton {
            containerView.addSubview(skipButton)
        }
    }
    
    private func setupGestures() {
        // Only allow overlay tap to dismiss for type 2
        if updateState.updateType == 2 {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
            overlayView.addGestureRecognizer(tapGesture)
        }
    }
    
    private func configureContent() {
        // Configure overlay
        overlayView.backgroundColor = theme.overlayColor
        
        // Configure title
        titleLabel.text = updateTitle
        titleLabel.textColor = customColors?.primaryTextColor ?? theme.textColor
        
        // Configure message
        let message = updateState.channelData.updateMessage.isEmpty 
            ? updateMessage 
            : updateState.channelData.updateMessage
        messageLabel.text = message
        messageLabel.textColor = customColors?.secondaryTextColor ?? theme.secondaryTextColor
        
        // Configure info button
        if shouldShowInfoButton {
            infoButton.tintColor = customColors?.linkColor ?? theme.linkColor
        }
        
        // Configure close button
        if shouldShowCloseButton {
            closeButton.tintColor = customColors?.closeButtonColor ?? theme.closeButtonColor
        }
        
        // Configure update button
        updateButton.setTitle(updateButtonText, for: .normal)
        updateButton.setTitleColor(updateButtonTextColor, for: .normal)
        updateButton.backgroundColor = updateButtonColor
        
        // Configure skip button
        if shouldShowSkipButton {
            updateSkipButtonTitle()
            skipButton.setTitleColor(customColors?.skipButtonTextColor ?? theme.secondaryTextColor, for: .normal)
            skipButton.backgroundColor = customColors?.skipButtonColor ?? .clear
        }
    }
    
    private func updateColors() {
        overlayView.backgroundColor = theme.overlayColor
        containerView.backgroundColor = resolveContainerBackgroundColor()
        
        titleLabel.textColor = customColors?.primaryTextColor ?? theme.textColor
        messageLabel.textColor = customColors?.secondaryTextColor ?? theme.secondaryTextColor
        
        if shouldShowInfoButton {
            infoButton.tintColor = customColors?.linkColor ?? theme.linkColor
        }
        
        if shouldShowCloseButton {
            closeButton.tintColor = customColors?.closeButtonColor ?? theme.closeButtonColor
        }
        
        updateButton.setTitleColor(updateButtonTextColor, for: .normal)
        updateButton.backgroundColor = updateButtonColor
        
        if shouldShowSkipButton {
            skipButton.setTitleColor(customColors?.skipButtonTextColor ?? theme.secondaryTextColor, for: .normal)
            skipButton.backgroundColor = customColors?.skipButtonColor ?? .clear
        }
    }
    
    private func setupConstraints() {
        // Clear any existing constraints
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        
        // Overlay constraints
        activeConstraints += [
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        // Container constraints
        activeConstraints += [
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.containerHorizontalMargin),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.containerHorizontalMargin)
        ]
        
        // Header buttons constraints
        setupHeaderButtonsConstraints()
        
        // Title constraints
        setupTitleConstraints()
        
        // Message constraints
        activeConstraints += [
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToMessageSpacing),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.contentHorizontalPadding),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.contentHorizontalPadding)
        ]
        
        // Update button constraints
        activeConstraints += [
            updateButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: Layout.messageToButtonSpacing),
            updateButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.contentHorizontalPadding),
            updateButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.contentHorizontalPadding),
            updateButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ]
        
        // Skip button or bottom constraint
        if shouldShowSkipButton {
            activeConstraints += [
                skipButton.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: Layout.buttonSpacing),
                skipButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.contentHorizontalPadding),
                skipButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.contentHorizontalPadding),
                skipButton.heightAnchor.constraint(equalToConstant: Layout.skipButtonHeight),
                skipButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.bottomMargin)
            ]
        } else {
            activeConstraints.append(
                updateButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.bottomMargin)
            )
        }
        
        NSLayoutConstraint.activate(activeConstraints)
    }
    
    private func setupHeaderButtonsConstraints() {
        let hasInfoButton = shouldShowInfoButton
        let hasCloseButton = shouldShowCloseButton
        
        if hasInfoButton {
            activeConstraints += [
                infoButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.headerButtonHorizontalMargin),
                infoButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.headerTopMargin),
                infoButton.widthAnchor.constraint(equalToConstant: Layout.headerButtonSize),
                infoButton.heightAnchor.constraint(equalToConstant: Layout.headerButtonSize)
            ]
        }
        
        if hasCloseButton {
            activeConstraints += [
                closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.headerButtonHorizontalMargin),
                closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.headerTopMargin),
                closeButton.widthAnchor.constraint(equalToConstant: Layout.headerButtonSize),
                closeButton.heightAnchor.constraint(equalToConstant: Layout.headerButtonSize)
            ]
        }
    }
    
    private func setupTitleConstraints() {
        let hasInfoButton = shouldShowInfoButton
        let hasCloseButton = shouldShowCloseButton
        
        // Calculate leading offset based on info button presence
        let leadingOffset = hasInfoButton 
            ? Layout.headerButtonHorizontalMargin + Layout.headerButtonSize + Layout.headerButtonToTitleSpacing
            : Layout.contentHorizontalPadding
        
        // Calculate trailing offset based on close button presence
        let trailingOffset = hasCloseButton
            ? -(Layout.headerButtonHorizontalMargin + Layout.headerButtonSize + Layout.headerButtonToTitleSpacing)
            : -Layout.contentHorizontalPadding
        
        activeConstraints += [
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.headerTopMargin),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leadingOffset),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailingOffset)
        ]
        
        // Align title vertically with buttons if they exist
        if hasInfoButton {
            activeConstraints.append(
                titleLabel.centerYAnchor.constraint(equalTo: infoButton.centerYAnchor)
            )
        } else if hasCloseButton {
            activeConstraints.append(
                titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor)
            )
        }
    }
    
    // MARK: - Helpers
    
    private var shouldShowInfoButton: Bool {
        return updateState.channelData.postUrl != nil
    }
    
    private var shouldShowCloseButton: Bool {
        return updateState.updateType == 2
    }
    
    private var shouldShowSkipButton: Bool {
        return updateState.updateType == 3 && remainingSkipAttempts > 0
    }
    
    private func updateSkipButtonTitle() {
        let title = "\(skipButtonText) (\(remainingSkipAttempts))"
        skipButton.setTitle(title, for: .normal)
    }
    
    // MARK: - Computed Properties for Custom Strings and Colors
    
    private var updateTitle: String {
        customStrings?.updateTitle ?? localization.updateTitle
    }
    
    private var updateMessage: String {
        customStrings?.updateMessage ?? localization.updateMessage
    }
    
    private var updateButtonText: String {
        customStrings?.updateButtonText ?? localization.updateButtonText
    }
    
    private var skipButtonText: String {
        customStrings?.skipButtonText ?? localization.skipButtonText
    }
    
    private var updateButtonColor: UIColor {
        customColors?.updateButtonColor ?? theme.primaryButtonColor
    }
    
    private var updateButtonTextColor: UIColor {
        customColors?.updateButtonTextColor ?? theme.primaryButtonTextColor
    }
    
    private func resolveContainerBackgroundColor() -> UIColor {
        customColors?.versionBackgroundColor ?? theme.backgroundColor
    }
    
    // MARK: - Actions
    
    @objc private func overlayTapped() {
        // This gesture is only added for type 2, but double-check
        guard updateState.updateType == 2 else { return }
        closeTapped()
    }
    
    @objc private func infoTapped() {
        onInfoTap?()
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }
    
    @objc private func updateTapped() {
        onUpdate?()
    }
    
    @objc private func skipTapped() {
        guard remainingSkipAttempts > 0 else { return }
        onSkip?(remainingSkipAttempts)
    }
    
    // MARK: - Public Methods
    
    /// Updates remaining skip attempts and refreshes UI
    /// - Parameter newValue: New remaining skip attempts count
    public func updateRemainingSkipAttempts(_ newValue: Int) {
        remainingSkipAttempts = newValue
        
        if newValue > 0 {
            updateSkipButtonTitle()
        } else {
            // Auto-dismiss when no skip attempts remaining
            dismiss(animated: true)
        }
    }
}

#endif
