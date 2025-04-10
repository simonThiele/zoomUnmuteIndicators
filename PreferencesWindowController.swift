import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    
    // UI elements
    private var enableBorderIndicatorCheckbox: NSButton!
    private var unmuteButtonTextField: NSTextField!
    
    // Singleton instance
    static var shared: PreferencesWindowController = {
        let controller = PreferencesWindowController()
        return controller
    }()
    
    init() {
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.center()
        
        super.init(window: window)
        
        // Set window delegate to self
        window.delegate = self
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Create UI elements
        let borderLabel = NSTextField(labelWithString: "Enable Border Indicator:")
        borderLabel.frame = NSRect(x: 20, y: 160, width: 200, height: 20)
        contentView.addSubview(borderLabel)
        
        enableBorderIndicatorCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        enableBorderIndicatorCheckbox.frame = NSRect(x: 230, y: 160, width: 20, height: 20)
        enableBorderIndicatorCheckbox.state = UserDefaults.standard.bool(forKey: "enableBorderIndicator") ? .on : .off
        contentView.addSubview(enableBorderIndicatorCheckbox)
        
        let buttonTextLabel = NSTextField(labelWithString: "Unmute Button Text:")
        buttonTextLabel.frame = NSRect(x: 20, y: 130, width: 200, height: 20)
        contentView.addSubview(buttonTextLabel)
        
        unmuteButtonTextField = NSTextField(frame: NSRect(x: 230, y: 130, width: 150, height: 20))
        unmuteButtonTextField.stringValue = UserDefaults.standard.string(forKey: "unmuteButtonText") ?? "Mute audio"
        contentView.addSubview(unmuteButtonTextField)
        
        // Add Save and Cancel buttons
        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePreferences(_:)))
        saveButton.frame = NSRect(x: 230, y: 20, width: 70, height: 30)
        saveButton.bezelStyle = .rounded
        contentView.addSubview(saveButton)
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelPreferences(_:)))
        cancelButton.frame = NSRect(x: 310, y: 20, width: 70, height: 30)
        cancelButton.bezelStyle = .rounded
        contentView.addSubview(cancelButton)
    }
    
    // Show the preferences window
    func showWindow() {
        if window?.isVisible == false {
            window?.center()
            window?.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        
        // Since this is a background app (LSUIElement = true), we need to
        // ensure the app becomes active and the window is visible
        NSApp.setActivationPolicy(.regular)
        window?.level = .floating
    }
    
    // Save preferences
    @IBAction func savePreferences(_ sender: Any) {
        UserDefaults.standard.set(enableBorderIndicatorCheckbox.state == .on, forKey: "enableBorderIndicator")
        UserDefaults.standard.set(unmuteButtonTextField.stringValue, forKey: "unmuteButtonText")
        
        // Post notification to inform AppDelegate that preferences have changed
        NotificationCenter.default.post(name: NSNotification.Name("PreferencesChanged"), object: nil)
        
        closeWindow()
    }
    
    // Cancel and close window
    @IBAction func cancelPreferences(_ sender: Any) {
        closeWindow()
    }
    
    // Common window closing code
    private func closeWindow() {
        // Return to background app status after window is closed
        // This is needed because we set the activation policy to .regular when showing the window
        NSApp.setActivationPolicy(.accessory)
        
        // Only close the window if it's not already in the process of closing
        if let window = window, window.isVisible {
            window.close()
        }
    }
    
    // Handle window closing via the close button
    func windowWillClose(_ notification: Notification) {
        // Just reset the activation policy, don't call close again
        NSApp.setActivationPolicy(.accessory)
    }
}
