import Cocoa

class BorderController: NSObject {
    var borderWindow: NSWindow?

    // constructor
    override init() {
        super.init()

        guard let mainScreen = NSScreen.main else { return }
        let screenRect = mainScreen.frame

        // remove old border window if it exists
        borderWindow?.orderOut(nil)

        borderWindow = NSWindow(
            contentRect: screenRect, // fullscreen
            styleMask: .borderless, // no title bar, no close/minimize buttons
            backing: .buffered,
            defer: false,
            screen: mainScreen
        )

        borderWindow?.level = .statusBar // on top of all windows, also dock and menu bar
        borderWindow?.isOpaque = false // transparent
        borderWindow?.backgroundColor = .clear
        borderWindow?.ignoresMouseEvents = true // mouse events go through!
        borderWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle] // ignore spaces and full screen

        let borderView = BorderView(frame: screenRect)
        borderWindow?.contentView = borderView

        borderWindow?.orderFrontRegardless() // show the window, even if it's behind other windows
    }

    deinit {
        borderWindow?.orderOut(nil) // remove the window when the object is deallocated
        borderWindow = nil
    }
}

class BorderView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawGradientRect()
    }

    func drawGradientRect() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let gradientColors = [NSColor.red.cgColor, NSColor.clear.cgColor]
        let gradientLocations: [CGFloat] = [0.0, 1.0]

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: gradientColors as CFArray,
                                        locations: gradientLocations) else { return }

        // from left to right
        var startPoint = CGPoint(x: bounds.minX, y: bounds.midY)
        var endPoint = CGPoint(x: bounds.minX + 40, y: bounds.midY)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsAfterEndLocation])

        // from bottom to top
        startPoint = CGPoint(x: bounds.midX, y: bounds.minY)
        endPoint = CGPoint(x: bounds.midX, y: bounds.minY + 40)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsAfterEndLocation])

        // from top to bottom
        startPoint = CGPoint(x: bounds.midX, y: bounds.maxY)
        endPoint = CGPoint(x: bounds.midX, y: bounds.maxY - 20)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsAfterEndLocation])

        // from right to left
        startPoint = CGPoint(x: bounds.maxX, y: bounds.midY)
        endPoint = CGPoint(x: bounds.maxX - 40, y: bounds.midY)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsAfterEndLocation])
    }
}
