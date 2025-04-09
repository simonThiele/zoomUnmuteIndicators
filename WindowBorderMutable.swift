import Cocoa

class WindowBorderMutable: Mutable {
    var borderController: BorderController?

    func setMute() {
        borderController?.borderWindow?.orderOut(nil)
        borderController = nil
    }

    func setUnmute() {
        borderController = BorderController()
    }
}
