import Foundation
import Logging

#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Monitors the background state of the application
public class BackgroundStateMonitor {
    /// The current app state
    private var currentAppState: AppState = .foreground
    
    /// The current battery state
    private var currentBatteryState = BatteryState()
    
    /// Listeners for app state changes
    private var appStateListeners: [AppStateListener] = []
    
    /// Listeners for battery state changes
    private var batteryStateListeners: [BatteryStateListener] = []
    
    /// Logger
    private let logger = Logger(label: "customfit.BackgroundStateMonitor")
    
    /// Initialize a new background state monitor
    public init() {
        #if os(iOS) || os(tvOS)
        // Register for app state notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Register for battery state notifications
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryStateChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryLevelChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        // Get the initial state
        updateAppState()
        updateBatteryState()
        #else
        // Default to foreground on non-iOS platforms
        currentAppState = .foreground
        
        // Default to good battery state on non-iOS platforms
        currentBatteryState = BatteryState(isLow: false, isCharging: true, level: 100)
        #endif
    }
    
    deinit {
        #if os(iOS) || os(tvOS)
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isBatteryMonitoringEnabled = false
        #endif
    }
    
    #if os(iOS) || os(tvOS)
    /// Handle app state changes
    @objc private func handleAppStateChange(_ notification: Notification) {
        updateAppState()
    }
    
    /// Handle battery state changes
    @objc private func handleBatteryStateChange(_ notification: Notification) {
        updateBatteryState()
    }
    
    /// Handle battery level changes
    @objc private func handleBatteryLevelChange(_ notification: Notification) {
        updateBatteryState()
    }
    
    /// Update the app state
    private func updateAppState() {
        let newState: AppState
        
        switch UIApplication.shared.applicationState {
        case .background:
            newState = .background
        case .active, .inactive:
            newState = .foreground
        @unknown default:
            newState = .foreground
        }
        
        if newState != currentAppState {
            currentAppState = newState
            logger.debug("App state changed: \(newState)")
            
            // Notify listeners
            for listener in appStateListeners {
                listener.onAppStateChange(state: newState)
            }
        }
    }
    
    /// Update the battery state
    private func updateBatteryState() {
        // Determine if the battery is low
        let level = UIDevice.current.batteryLevel
        let isLow = level >= 0 && level <= 0.2 // Consider 20% or below as low
        
        // Determine if the device is charging
        let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        
        // Convert battery level to a percentage
        let levelPercentage = level < 0 ? 100 : Int(level * 100)
        
        let newState = BatteryState(isLow: isLow, isCharging: isCharging, level: levelPercentage)
        
        if newState.isLow != currentBatteryState.isLow ||
           newState.isCharging != currentBatteryState.isCharging ||
           newState.level != currentBatteryState.level {
            
            currentBatteryState = newState
            logger.debug("Battery state changed: low=\(newState.isLow), charging=\(newState.isCharging), level=\(newState.level)")
            
            // Notify listeners
            for listener in batteryStateListeners {
                listener.onBatteryStateChange(state: newState)
            }
        }
    }
    #endif
    
    /// Add a listener for app state changes
    /// - Parameter listener: The listener to add
    public func addAppStateListener(_ listener: @escaping (AppState) -> Void) {
        let appStateListener = AppStateListenerWrapper(callback: listener)
        appStateListeners.append(appStateListener)
        
        // Immediately notify the listener of the current state
        listener(currentAppState)
    }
    
    /// Add a listener for battery state changes
    /// - Parameter listener: The listener to add
    public func addBatteryStateListener(_ listener: @escaping (BatteryState) -> Void) {
        let batteryStateListener = BatteryStateListenerWrapper(callback: listener)
        batteryStateListeners.append(batteryStateListener)
        
        // Immediately notify the listener of the current state
        listener(currentBatteryState)
    }
    
    /// Get the current app state
    /// - Returns: The current app state
    public func getCurrentAppState() -> AppState {
        return currentAppState
    }
    
    /// Get the current battery state
    /// - Returns: The current battery state
    public func getCurrentBatteryState() -> BatteryState {
        return currentBatteryState
    }
}

/// Wrapper for app state listener closure
private class AppStateListenerWrapper: AppStateListener {
    private let callback: (AppState) -> Void
    
    init(callback: @escaping (AppState) -> Void) {
        self.callback = callback
    }
    
    func onAppStateChange(state: AppState) {
        callback(state)
    }
}

/// Wrapper for battery state listener closure
private class BatteryStateListenerWrapper: BatteryStateListener {
    private let callback: (BatteryState) -> Void
    
    init(callback: @escaping (BatteryState) -> Void) {
        self.callback = callback
    }
    
    func onBatteryStateChange(state: BatteryState) {
        callback(state)
    }
} 