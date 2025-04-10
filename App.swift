import Cocoa
import OSAKit

protocol Mutable {
    func setMute()
    func setUnmute()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: Timer?
    var mutables: [Mutable] = []
    var buttonTextToSearchFor = "Mute audio"
    
    // Keys for UserDefaults
    private let enableBorderIndicatorKey = "enableBorderIndicator"
    private let unmuteButtonTextKey = "unmuteButtonText"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (menu bar app)
        NSApp.setActivationPolicy(.accessory)
        
        // Register default values
        registerDefaultPreferences()
        
        // Setup menu bar
        setupMenuBar()
        
        // Load preferences and initialize mutables
        loadPreferencesAndInitializeMutables()
        
        // Observe preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: NSNotification.Name("PreferencesChanged"),
            object: nil
        )
        
        // Prepare JXA script with button text from preferences
        prepareJXAScript()
        
        // Start monitoring Zoom status
        startMonitoring()
    }
    
    // Register default values for preferences
    private func registerDefaultPreferences() {
        let defaults: [String: Any] = [
            enableBorderIndicatorKey: true,
            unmuteButtonTextKey: "Mute audio"
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    // Setup menu bar with app menu
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        // App menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Preferences item
        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        appMenu.addItem(preferencesItem)
        
        // Separator
        appMenu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)
    }
    
    // Load preferences and initialize mutables
    private func loadPreferencesAndInitializeMutables() {
        // Clear existing mutables
        mutables.removeAll()
        
        // Get preferences
        let enableBorder = UserDefaults.standard.bool(forKey: enableBorderIndicatorKey)
        buttonTextToSearchFor = UserDefaults.standard.string(forKey: unmuteButtonTextKey) ?? "Mute audio"
        
        // Always add menu bar indicator
        mutables.append(MenuBarMutable())
        
        // Initialize border indicator based on preferences
        if enableBorder {
            mutables.append(WindowBorderMutable())
        }
        
        print("Button text to search for: \(buttonTextToSearchFor)")
    }
    
    // Start monitoring Zoom status
    private func startMonitoring() {
        var latestMuteState: Bool? = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let muteState = self.callJXACheck()
            let unmuted = muteState == "Unmuted"
            
            if latestMuteState == unmuted {
                return // no change -> nothing todo
            }
            latestMuteState = unmuted
            
            for mutable in self.mutables {
                if unmuted {
                    mutable.setUnmute()
                } else {
                    mutable.setMute()
                }
            }
        }
    }
    
    // Open preferences window
    @objc func openPreferences() {
        PreferencesWindowController.shared.showWindow()
    }
    
    // Handle preferences changed notification
    @objc func preferencesChanged() {
        // Reload preferences and reinitialize mutables
        loadPreferencesAndInitializeMutables()
        
        // Update JXA script with new button text
        prepareJXAScript()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Invalidate the timer when the application is about to terminate
        timer?.invalidate()
        timer = nil
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }

    var script: OSAScript!
    func prepareJXAScript() {
        guard let language = OSALanguage(forName: "JavaScript") else {
            print("Language not found")
            return
        }
        let scriptWithFilledPlaceholder = jxaScriptContent.replacingOccurrences(of: "{{PLACEHOLDER}}", with: buttonTextToSearchFor)
        script = OSAScript(source: scriptWithFilledPlaceholder, language: language)

        var compileError: NSDictionary?
        guard script.compileAndReturnError(&compileError) else {
            print("Compile error: \(compileError ?? [:])")
            return
        }
    }

    func callJXACheck() -> String? {
        var executionError: NSDictionary?
        guard let resultDescriptor = script.executeAndReturnError(&executionError) else {
            print("Execution error: \(executionError ?? [:])")
            return nil
        }
        return resultDescriptor.stringValue ?? nil
    }
}

let jxaScriptContent = """
ObjC.import("Foundation");

function checkZoomStatus() {
  const btnTitle = "{{PLACEHOLDER}}";

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
