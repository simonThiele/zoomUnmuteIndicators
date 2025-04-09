import Cocoa
import OSAKit

protocol Mutable {
    func setMute()
    func setUnmute()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: Timer?

    var mutables: [Mutable] = [
    ]

    func applicationDidFinishLaunching(_: Notification) {
        for argument in CommandLine.arguments {
            if argument == "--withMenuBarIndicator" {
                mutables.append(MenuBarMutable())
            }
            if argument == "--withWindowBorderIndicator" {
                mutables.append(WindowBorderMutable())
            }
        }
        if mutables.count == 0 {
            print("No arguments provided. Please use --withMenuBarIndicator or --withWindowBorderIndicator.")
            return
        }

        prepareJXAScript()

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

    func applicationWillTerminate(_: Notification) {
        // Invalidate the timer when the application is about to terminate
        timer?.invalidate()
        timer = nil
    }

    var script: OSAScript!
    func prepareJXAScript() {
        guard let language = OSALanguage(forName: "JavaScript") else {
            print("Language not found")
            return
        }
        script = OSAScript(source: jxaScriptContent, language: language)

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
  const btnTitle = "Mute audio";

  const systemEvents = Application("System Events");
  const zoomApp = Application("zoom.us");

  if (zoomApp.running()) {
    const zoomProcess = systemEvents.processes["zoom.us"];
    try {
      const menuItemExists =
        zoomProcess.menuBars[0].menuBarItems["Meeting"].menus[0].menuItems[
          btnTitle
        ].exists();

      return menuItemExists ? "Unmuted" : "Muted";
    } catch (e) {
      return "Muted";
    }
  }
}

checkZoomStatus();
"""
