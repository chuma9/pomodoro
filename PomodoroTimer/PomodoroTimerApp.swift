import SwiftUI
import AppKit
import Carbon
import UserNotifications

@main
struct PomodoroTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timer: Timer?
    var pomodoroManager = PomodoroManager()
    var globalMonitor: Any?
    var localMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()
        setupMenuBar()
        setupGlobalShortcuts()
        startTimer()
        
        // Add notification observer for app activation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Add notification observer for timer state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerStateChanged),
            name: NSNotification.Name("TimerStateChanged"),
            object: nil
        )
        
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
    }
    
    deinit {
        cleanup()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        // Check for daily reset when app becomes active
        pomodoroManager.checkDailyReset()
    }
    
    @objc func timerStateChanged(_ notification: Notification) {
        updateTimerState()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if !granted {
                print("Notification sound permission not granted.")
            }
        }
    }
    
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "⏳ You're doing great!"
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 430)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(pomodoroManager: pomodoroManager))
    }
    
    func setupGlobalShortcuts() {
        // Global monitor for when app is not active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        // Local monitor for when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Check for Command+Shift modifier combination
        let modifiers = event.modifierFlags
        if modifiers.contains([.command, .shift]) && !modifiers.contains([.option, .control]) {
            switch event.keyCode {
            case 49: // Space key
                DispatchQueue.main.async { [weak self] in
                    print("Space shortcut triggered")
                    self?.pomodoroManager.toggleTimer()
                    self?.updateTimerState()
                }
            case 15: // R key
                DispatchQueue.main.async { [weak self] in
                    print("R shortcut triggered")
                    self?.pomodoroManager.resetTimer()
                    self?.updateTimerState()
                }
            case 1: // S key
                DispatchQueue.main.async { [weak self] in
                    print("S shortcut triggered")
                    self?.pomodoroManager.skipToNextPhase()
                    self?.updateTimerState()
                }
            default:
                break
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                // Check for daily reset when opening the popover
                pomodoroManager.checkDailyReset()
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover?.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func startTimer() {
        // Only start timer if pomodoro is running
        if pomodoroManager.isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                // Only update timer if it's running
                if self.pomodoroManager.isRunning {
                    self.pomodoroManager.updateTimer()
                    self.updateMenuBarTitle()
                } else {
                    // Stop timer if pomodoro is not running
                    self.stopTimer()
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateTimerState() {
        if pomodoroManager.isRunning {
            if timer == nil {
                startTimer()
            }
        } else {
            stopTimer()
        }
        updateMenuBarTitle()
    }
    
    func updateMenuBarTitle() {
        if let button = statusItem?.button {
            let timeString = pomodoroManager.formattedTime
            let emoji = pomodoroManager.currentPhase == .focus ? "👩🏾‍💻" : "☕"
            button.title = "\(emoji) \(timeString)"
        }
    }
    
    private func cleanup() {
        // Clean up timer
        stopTimer()
        
        // Clean up monitors
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
} 
