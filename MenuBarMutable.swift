import Cocoa

class MenuBarMutable: Mutable {
  var statusItem: NSStatusItem!

  // constructor
  init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "🌕" // start with unknown
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
