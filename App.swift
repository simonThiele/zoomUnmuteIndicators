import Cocoa

protocol Mutable {
    func setMute()
    func setUnmute()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?

    private var mutables: [Mutable] = []
    private var buttonTextToSearchFor = "Mute audio" // "default"
    private var latestMuteState: Bool? = nil // nil -> unknown

    private let enableBorderIndicatorKey = "enableBorderIndicator"
    private let muteButtonTextKey = "muteButtonText"

    private var jxaScriptContent = ""

    func applicationDidFinishLaunching(_: Notification) {
        // Set activation policy to accessory (menu bar app)
        NSApp.setActivationPolicy(.accessory)

        registerDefaultPreferences()

        // Setup menu bar

        // Load preferences and initialize mutables
        loadPreferencesAndInitialize()

        // Observe preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: NSNotification.Name("PreferencesChanged"),
            object: nil
        )

        prepareJXAScript()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // Check if self still exists
            guard let self = self else { return }

            let result = self.executeJxaViaOsaScript()
            let muteState = result ?? "Muted"
            let unmuted = muteState == "Unmuted"
            if self.latestMuteState == unmuted {
                return // No change -> nothing todo
            }
            self.latestMuteState = unmuted

            for mutable in self.mutables {
                if unmuted {
                    mutable.setUnmute()
                } else {
                    mutable.setMute()
                }
            }
        }
    }

    // Register default values for preferences
    private func registerDefaultPreferences() {
        let defaults: [String: Any] = [
            enableBorderIndicatorKey: true,
            muteButtonTextKey: buttonTextToSearchFor,
        ]
        UserDefaults.standard.register(defaults: defaults)
    }

    // Load preferences and initialize mutables
    private func loadPreferencesAndInitialize() {
        mutables.removeAll()

        // Get preferences
        let enableBorder = UserDefaults.standard.bool(forKey: enableBorderIndicatorKey)
        buttonTextToSearchFor = UserDefaults.standard.string(forKey: muteButtonTextKey) ?? "Mute audio"

        // Always add menu bar indicator
        mutables.append(MenuBarMutable())

        // Initialize border indicator based on preferences
        if enableBorder {
            mutables.append(WindowBorderMutable())
        }
    }

    // Open preferences window
    @objc func openPreferences() {
        PreferencesWindowController.shared.showWindow()
    }

    @objc func preferencesChanged() {
        // Reload preferences and reinitialize mutables
        loadPreferencesAndInitialize()

        // Reset the state to unknown
        latestMuteState = nil

        // Update JXA script with new button text
        prepareJXAScript()
    }

    func applicationWillTerminate(_notification _: Notification) {
        // Invalidate the timer when the application is about to terminate
        timer?.invalidate()
        timer = nil

        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }

    func prepareJXAScript() {
        jxaScriptContent = getJXAScriptContent()
    }

    func executeJxaViaOsaScript() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript", "-e", jxaScriptContent]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return outputString

        } catch {
            print("Error running osascript: \(error)")
            return nil
        }
    }

    func getJXAScriptContent() -> String {
        return """
        ObjC.import("Foundation");

        function checkZoomStatus() {
          const btnTitle = "\(buttonTextToSearchFor)";

          const systemEvents = Application("System Events");
          const zoomApp = Application("zoom.us");

          if (zoomApp.running()) {
            const zoomProcess = systemEvents.processes["zoom.us"];
            try {
          	  const menuItemExists = zoomProcess.menuBars[0].menuBarItems["Meeting"].menus[0].menuItems[btnTitle].exists()
              return menuItemExists ? "Unmuted" : "Muted";
            } catch (e) {
              return "Muted";
            }
          }
        }
        checkZoomStatus();
        """
    }
}
