import Cocoa

protocol Mutable {
    func setMute()
    func setUnmute()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: Timer?

    var mutables: [Mutable] = []
    var buttonTextToSearchFor = "Mute audio" // "Default english"
    var latestMuteState: Bool? = nil

    func applicationDidFinishLaunching(_: Notification) {
        for argument in CommandLine.arguments {
            if argument == "--withMenuBarIndicator" {
                mutables.append(MenuBarMutable())
            }
            if argument == "--withWindowBorderIndicator" {
                mutables.append(WindowBorderMutable())
            }

            // starts with "--unmuteButtonText"
            if argument.hasPrefix("--unmuteButtonText=") {
                let text = String(argument.split(separator: "=")[1])
                if text.count > 0 {
                    buttonTextToSearchFor = text
                }
            }
        }
        if mutables.count == 0 {
            print("No arguments provided. Please use --withMenuBarIndicator or --withWindowBorderIndicator.")
            return
        }

        print("Button text to search for: \(buttonTextToSearchFor)")

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

    func applicationWillTerminate(_: Notification) {
        // Invalidate the timer when the application is about to terminate
        timer?.invalidate()
        timer = nil
    }

    func prepareJXAScript() {
        jxaScriptContent = jxaScriptContent.replacingOccurrences(of: "{{PLACEHOLDER}}", with: buttonTextToSearchFor)
    }

    func executeJxaViaOsaScript() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        // Argumente: JavaScript-Sprache angeben (-l) und Skript als Text übergeben (-e)
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
}

var jxaScriptContent = """
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
