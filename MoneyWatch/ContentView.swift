import SwiftUI
import Dispatch
import Foundation
import AppKit

// MARK: - Main Content View with AppKit Timer
struct ContentView: View {
    // MARK: - State/UI Properties
    @State private var isRunning = false
    @State private var displayTime: String = "0:00:00.00"
    @State private var displayEarnings: String = "USD$0.00"
    @State private var showingPayRateInput = false
    @State private var showingSidebar: Bool = false
    @State private var payouts: [PayoutRecord] = []
    
    // Use a class that won't trigger SwiftUI redraws
    private let timerController = LowLevelTimerController()
    
    var body: some View {
        HSplitView {
            // Sidebar (conditional)
            if showingSidebar {
                SidebarView(payouts: $payouts)
                    .transition(.move(edge: .leading))
            }
            
            // Main content
            ZStack {
                Color(NSColor.windowBackgroundColor).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Money earned display
                    Text(displayEarnings)
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                        .monospacedDigit()
                        .padding(.top, 40)
                    
                    // Time display
                    Text(displayTime)
                        .font(.system(size: 52, weight: .thin, design: .default))
                        .foregroundColor(Color(NSColor.labelColor))
                        .monospacedDigit()
                        .kerning(0.5)
                        .padding(.vertical, 10)
                    
                    // Control buttons
                    HStack(spacing: 36) {
                        // Start/Pause button
                        Button(action: toggleTimer) {
                            ZStack {
                                Circle()
                                    .fill(isRunning ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(isRunning ? .red : .green)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Reset button
                        Button(action: resetTimer) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(timerController.elapsedTime == 0 && !isRunning)
                    }
                    .padding(.vertical, 20)
                    
                    // Bottom controls - first row
                    HStack(spacing: 20) {
                        // Payout button
                        Button(action: createPayout) {
                            Label("Payout", systemImage: "dollarsign.square")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(timerController.calculateTotalEarnings() <= 0)
                        
                        // History toggle button
                        Button(action: {
                            withAnimation {
                                showingSidebar.toggle()
                            }
                        }) {
                            Label(showingSidebar ? "Hide History" : "Show History",
                                  systemImage: showingSidebar ? "sidebar.left" : "sidebar.right")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Bottom controls - second row
                    HStack(spacing: 20) {
                        // Change pay rate button (only when paused)
                        if !isRunning {
                            Button(action: { showingPayRateInput = true }) {
                                Label("Change Pay Rate", systemImage: "dollarsign.circle")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Currency swap button (USD/CAD)
                        Button(action: { toggleCurrency() }) {
                            Label(timerController.isCanadian ? "Switch to USD" : "Switch to CAD", systemImage: "arrow.left.arrow.right")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Current pay rate display
                    VStack(spacing: 5) {
                        Text("Current rate: \(timerController.isCanadian ? "CAD$" : "USD$")\(String(format: "%.2f", timerController.hourlyRate))/hour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if timerController.isCanadian {
                            Text("Exchange rate: 1 USD = \(String(format: "%.4f", timerController.exchangeRate)) CAD")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding()
                .frame(minWidth: 350, minHeight: 500)
            }
        }
        .sheet(isPresented: $showingPayRateInput) {
            PayRateInputView(
                hourlyRate: Binding(
                    get: { timerController.hourlyRate },
                    set: { timerController.hourlyRate = $0 }
                ),
                isPresented: $showingPayRateInput,
                accumulatedEarnings: Binding(
                    get: { timerController.accumulatedEarnings },
                    set: { timerController.accumulatedEarnings = $0 }
                ),
                lastPayRateChangeTime: Binding(
                    get: { timerController.lastPayRateChangeTime },
                    set: { timerController.lastPayRateChangeTime = $0 }
                ),
                elapsedTime: Binding(
                    get: { timerController.elapsedTime },
                    set: { timerController.elapsedTime = $0 }
                ),
                currency: timerController.isCanadian ? "CAD$" : "USD$"
            )
        }
        .onAppear {
            // Initialize controller and set up callback
            timerController.onUpdate = { [self] time, earnings in
                // Limit UI updates to 15 per second at most
                DispatchQueue.main.async {
                    self.displayTime = time
                    self.displayEarnings = earnings
                }
            }
            
            // Load saved payouts
            payouts = PayoutStorage.shared.loadPayouts()
        }
        .onChange(of: payouts) { newPayouts in
            // Save payouts whenever they change
            PayoutStorage.shared.savePayouts(newPayouts)
        }
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        
        if isRunning {
            timerController.startTimer()
        } else {
            timerController.stopTimer()
        }
    }
    
    private func resetTimer() {
        isRunning = false
        timerController.resetTimer()
    }
    
    private func toggleCurrency() {
        timerController.toggleCurrency()
    }
    
    private func createPayout() {
        // Only create payout if there are earnings to record
        let currentEarnings = timerController.calculateTotalEarnings()
        if currentEarnings > 0 {
            // Always store the USD amount
            let usdAmount = currentEarnings
            
            // Record the payout (always in USD)
            let newPayout = PayoutRecord(
                amount: usdAmount,
                timestamp: Date()
            )
            
            // Add to payouts list
            withAnimation {
                payouts.insert(newPayout, at: 0) // Insert at top
            }
            
            // Show sidebar if it's not already visible
            if !showingSidebar {
                withAnimation {
                    showingSidebar = true
                }
            }
            
            // Reset the timer and earnings
            resetTimer()
        }
    }
}

// MARK: - Low Level Timer Controller
// This class uses a more efficient timer implementation
final class LowLevelTimerController: NSObject {
    // Timer state
    var elapsedTime: TimeInterval = 0
    var hourlyRate: Double = 40.0
    var isCanadian: Bool = false
    var exchangeRate: Double = 1.4
    var accumulatedEarnings: Double = 0.0
    var lastPayRateChangeTime: TimeInterval = 0.0
    
    // Private timing properties
    private var timerStartDate: Date?
    private var displayTimer: Timer?
    private var isRunning = false
    private var lastUIUpdateTime: TimeInterval = 0
    
    // Callback for UI updates
    var onUpdate: ((String, String) -> Void)?
    
    // Set up
    override init() {
        super.init()
        
        // Initialize currency service
        exchangeRate = CurrencyService.shared.getCurrentCADRate()
        CurrencyService.shared.startRegularUpdates()
    }
    
    deinit {
        stopTimer()
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        // Save current time as the start of new rate period
        lastPayRateChangeTime = elapsedTime
        
        // Mark as running
        isRunning = true
        
        // Set the start time
        timerStartDate = Date()
        
        // Use a low-frequency timer for display updates (60 fps is enough for a stopwatch)
        displayTimer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        // Add to common run loop mode to ensure updates even during UI interactions
        RunLoop.current.add(displayTimer!, forMode: .common)
    }
    
    func stopTimer() {
        guard isRunning else { return }
        
        // Calculate and store earnings up to this point
        updateTimerState()
        
        let currentSessionEarnings = hourlyRate * (elapsedTime - lastPayRateChangeTime) / 3600
        accumulatedEarnings += currentSessionEarnings
        lastPayRateChangeTime = elapsedTime
        
        // Mark as stopped
        isRunning = false
        timerStartDate = nil
        
        // Stop the timer
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Final update
        notifyUI()
    }
    
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        accumulatedEarnings = 0
        lastPayRateChangeTime = 0
        
        // Update UI after reset
        notifyUI()
    }
    
    func calculateTotalEarnings() -> Double {
        // Update state if running
        if isRunning {
            updateTimerState()
        }
        
        // Accumulated earnings from previous sessions or rate changes
        let storedEarnings = accumulatedEarnings
        
        // Current session earnings with current rate
        let currentEarnings = isRunning ?
            hourlyRate * (elapsedTime - lastPayRateChangeTime) / 3600 : 0
            
        return storedEarnings + currentEarnings
    }
    
    func toggleCurrency() {
        isCanadian.toggle()
        
        // Fetch fresh rates when switching to CAD
        if isCanadian {
            CurrencyService.shared.fetchLatestRates { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.exchangeRate = CurrencyService.shared.getCurrentCADRate()
                    self.notifyUI()
                }
            }
        } else {
            notifyUI()
        }
    }
    
    @objc private func updateTimer() {
        // Update time based on real elapsed time
        updateTimerState()
        
        // Throttle UI updates to reduce CPU load (max 15fps)
        let now = Date().timeIntervalSinceReferenceDate
        if now - lastUIUpdateTime >= 1.0/15.0 {
            notifyUI()
            lastUIUpdateTime = now
        }
    }
    
    private func updateTimerState() {
        if isRunning, let startDate = timerStartDate {
            // Calculate elapsed time based on actual system time for accuracy
            let now = Date()
            let additionalTime = now.timeIntervalSince(startDate)
            let newElapsedTime = elapsedTime + additionalTime
            
            // Reset start date to now (for next calculation)
            timerStartDate = now
            
            // Update state
            elapsedTime = newElapsedTime
        }
    }
    
    private func notifyUI() {
        // Format time display
        let timeString = formatTimeInterval(elapsedTime)
        
        // Format earnings display
        let totalEarnings = calculateTotalEarnings()
        let displayAmount = isCanadian ? totalEarnings * exchangeRate : totalEarnings
        let currencySymbol = isCanadian ? "CAD$" : "USD$"
        let earningsString = "\(currencySymbol)\(String(format: "%.2f", displayAmount))"
        
        // Notify UI
        onUpdate?(timeString, earningsString)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%01d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
