import Foundation
import SwiftUI
import QuartzCore

// A timer class that synchronizes with the display refresh rate (like CADisplayLink)
// This is similar to how Apple's native apps maintain smooth animations with low CPU usage
class DisplayLinkTimer: ObservableObject {
    @Published var onTick: (() -> Void)?
    private var displayLink: CVDisplayLink?
    private var lastTime: CFTimeInterval = 0
    
    // Start and stop flags for thread-safe operation
    private var isRunning = false
    
    init() {
        setupDisplayLink()
    }
    
    deinit {
        stop()
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        CVDisplayLinkStart(displayLink!)
    }
    
    func stop() {
        guard isRunning, displayLink != nil else { return }
        isRunning = false
        CVDisplayLinkStop(displayLink!)
    }
    
    private func setupDisplayLink() {
        // Create the display link
        var displayLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        self.displayLink = displayLink
        
        // Set the output callback
        let callback: CVDisplayLinkOutputCallback = { (_, _, _, _, _, userInfo) -> CVReturn in
            // Extract self from the userInfo
            let timer = Unmanaged<DisplayLinkTimer>.fromOpaque(userInfo!).takeUnretainedValue()
            
            // Call the tick handler on the main thread to update UI
            if timer.isRunning {
                DispatchQueue.main.async {
                    timer.onTick?()
                }
            }
            
            return kCVReturnSuccess
        }
        
        // Set self as the user info so we can access it in the callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink!, callback, userInfo)
    }
}
