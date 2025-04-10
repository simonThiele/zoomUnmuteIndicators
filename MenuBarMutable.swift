import Cocoa

class MenuBarMutable: Mutable {
  var statusItem: NSStatusItem!
  
  // constructor
  init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "🌕" // start with unknown
    
    // Setup menu for the status item
    setupMenu()
  }
  
  private func setupMenu() {
    let menu = NSMenu()
    
    // Preferences item
    let preferencesItem = NSMenuItem(
      title: "Preferences...",
      action: #selector(openPreferences),
      keyEquivalent: ","
    )
    preferencesItem.target = self
    menu.addItem(preferencesItem)
    
    // Separator
    menu.addItem(NSMenuItem.separator())
    
    // Quit item
    let quitItem = NSMenuItem(
      title: "Quit",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    menu.addItem(quitItem)
    
    // Assign menu to status item
    statusItem.menu = menu
  }
  
  @objc private func openPreferences() {
    PreferencesWindowController.shared.showWindow()
  }
  
  func setMute() {
    statusItem.button?.title = "🟢"
  }
  
  func setUnmute() {
    statusItem.button?.title = "🔴"
  }
  
  deinit {
    NSStatusBar.system.removeStatusItem(statusItem)
  }
}
