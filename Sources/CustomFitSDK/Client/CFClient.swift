import Foundation
import Logging

/// Connection status
public enum ConnectionStatus {
    /// Connected to the API
    case connected
    /// Disconnected from the API
    case disconnected
    /// Connection status is unknown
    case unknown
}

/// Information about a connection
public struct ConnectionInformation {
    /// When the last successful connection was made (in milliseconds since epoch)
    public let lastSuccessfulConnectionTimeMs: UInt64
    /// Any error that occurred
    public let error: Error?
    
    /// Initialize with connection information
    /// - Parameters:
    ///   - lastSuccessfulConnectionTimeMs: When the last successful connection was made
    ///   - error: Any error that occurred
    public init(lastSuccessfulConnectionTimeMs: UInt64 = 0, error: Error? = nil) {
        self.lastSuccessfulConnectionTimeMs = lastSuccessfulConnectionTimeMs
        self.error = error
    }
}

/// Connection status listener
public protocol ConnectionStatusListener: AnyObject {
    /// Called when connection status changes
    /// - Parameters:
    ///   - newStatus: The new status
    ///   - info: Information about the connection
    func onConnectionStatusChanged(newStatus: ConnectionStatus, info: ConnectionInformation)
}

/// Application state
public enum AppState {
    /// Application is in the foreground
    case foreground
    /// Application is in the background
    case background
}

/// Application state listener
public protocol AppStateListener: AnyObject {
    /// Called when application state changes
    /// - Parameter state: The new state
    func onAppStateChange(state: AppState)
}

/// Battery state
public struct BatteryState {
    /// Whether the battery is low
    public let isLow: Bool
    /// Whether the device is charging
    public let isCharging: Bool
    /// Battery level (0-100)
    public let level: Int
    
    /// Initialize with battery state
    /// - Parameters:
    ///   - isLow: Whether the battery is low
    ///   - isCharging: Whether the device is charging
    ///   - level: Battery level (0-100)
    public init(isLow: Bool = false, isCharging: Bool = true, level: Int = 100) {
        self.isLow = isLow
        self.isCharging = isCharging
        self.level = level
    }
}

/// Battery state listener
public protocol BatteryStateListener: AnyObject {
    /// Called when battery state changes
    /// - Parameter state: The new state
    func onBatteryStateChange(state: BatteryState)
}

/// Feature flag change listener
public protocol FeatureFlagChangeListener: AnyObject {
    /// Called when a feature flag changes
    /// - Parameter newValue: The new value
    func onFeatureFlagChange(newValue: Any)
}

/// Create a protocol for listeners that is Hashable
private protocol AllFlagsListener: Hashable {
    func onAllFlagsChanged(flags: [String: Any])
}

/// Wrapper class for the all flags listener function that conforms to Hashable
private class AllFlagsListenerWrapper: AllFlagsListener {
    private let id = UUID()
    private let callback: ([String: Any]) -> Void
    
    init(callback: @escaping ([String: Any]) -> Void) {
        self.callback = callback
    }
    
    func onAllFlagsChanged(flags: [String: Any]) {
        callback(flags)
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AllFlagsListenerWrapper, rhs: AllFlagsListenerWrapper) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Main client for the CustomFit SDK
public final class _CFClient {
    /// The session ID for this client
    private let sessionId: String = UUID().uuidString
    
    /// The configuration for the client
    private var config: CFConfig
    
    /// The user for whom to evaluate feature flags
    private let user: CFUser
    
    /// HTTP client for API communication
    private let httpClient: HttpClient
    
    /// Event tracker for tracking events
    private let eventTracker: EventTracker
    
    /// Summary manager for sending summaries
    private let summaryManager: SummaryManager
    
    /// Config fetcher for fetching configurations
    private let configFetcher: ConfigFetcher
    
    /// Connection manager
    private var connectionManager: ConnectionManager
    
    /// Background state monitor
    private let backgroundStateMonitor: BackgroundStateMonitor
    
    /// Connection status listeners
    private var connectionStatusListeners: [ConnectionStatusListener] = []
    
    /// Device context
    private var deviceContext: _DeviceContext
    
    /// Evaluation contexts
    private var contexts: [String: EvaluationContext] = [:]
    
    /// Previous last modified timestamp
    private var previousLastModified: String?
    
    /// Configuration map
    private var configMap: [String: Any] = [:]
    
    /// Config mutex for atomic updates
    private let configMutex = NSLock()
    
    /// SDK settings semaphore
    private let sdkSettingsSemaphore = DispatchSemaphore(value: 0)
    
    /// SDK settings timer
    private var sdkSettingsTimer: DispatchSourceTimer?
    
    /// Timer mutex for atomic updates
    private let timerMutex = NSLock()
    
    /// Config listeners
    private var configListeners: [String: [(Any) -> Void]] = [:]
    
    /// Feature flag listeners
    private var featureFlagListeners: [String: [FeatureFlagChangeListener]] = [:]
    
    /// All flags listeners
    private var allFlagsListeners: Set<AllFlagsListenerWrapper> = []
    
    /// Application info
    private var applicationInfo: _ApplicationInfo?
    
    /// Logger
    private let logger = Logger(label: "customfit._CFClient")
    
    /// Private initializer to enforce singleton pattern
    private init(config: CFConfig, user: CFUser) {
        self.config = config
        self.user = user
        
        // Initialize dependencies
        self.httpClient = HttpClient(config: config)
        
        // Initialize summaryManager before eventTracker since eventTracker depends on it
        self.summaryManager = SummaryManager(
            sessionId: sessionId,
            httpClient: httpClient,
            user: user,
            config: config
        )
        
        // Initialize eventTracker after summaryManager
        self.eventTracker = EventTracker(
            sessionId: sessionId,
            httpClient: httpClient,
            user: user,
            summaryManager: summaryManager,
            config: config
        )
        
        self.configFetcher = ConfigFetcher(
            httpClient: httpClient,
            config: config,
            user: user
        )
        
        // Create a placeholder connection manager - will set onConnected callback after full initialization
        self.connectionManager = ConnectionManager { }
        
        self.backgroundStateMonitor = BackgroundStateMonitor()
        self.deviceContext = _DeviceContext.createBasic()
        
        // Now that all properties are initialized, we can do the rest of the setup
        setupConnectionManager()
        initialize()
    }
    
    /// Sets up the connection manager with the proper callback after full initialization
    private func setupConnectionManager() {
        connectionManager = ConnectionManager { [weak self] in
            guard let self = self else { return }
            do {
                try self.checkSdkSettings()
            } catch {
                self.logger.error("Error checking SDK settings: \(error)")
            }
        }
    }
    
    /// Initialize the client
    private func initialize() {
        // Set initial offline mode from the config
        if config.offlineMode {
            configFetcher.setOffline(true)
            connectionManager.setOfflineMode(true)
            logger.info("CF client initialized in offline mode")
        }
        
        // Initialize environment attributes based on config
        if config.autoEnvAttributesEnabled {
            logger.debug("Auto environment attributes enabled, detecting device and application info")
            
            // Initialize device context if it's not already set
            let existingDeviceContext = user.getDeviceContext()
            if existingDeviceContext == nil {
                deviceContext = _DeviceContext.createBasic()
                // Update user with device context
                updateUserWithDeviceContext()
            } else {
                // Use the device context from the user if available
                deviceContext = existingDeviceContext!
            }
            
            // Get application info from user if available, otherwise detect it
            let existingAppInfo = user.getApplicationInfo()
            if existingAppInfo != nil {
                applicationInfo = existingAppInfo
                // Increment launch count
                let updatedAppInfo = existingAppInfo!.copyWith(launchCount: existingAppInfo!.launchCount + 1)
                updateUserWithApplicationInfo(updatedAppInfo)
            } else {
                // Try to auto-detect application info
                // In Swift this would typically involve using Bundle info
                let bundle = Bundle.main
                if let appName = bundle.infoDictionary?["CFBundleName"] as? String,
                   let appId = bundle.bundleIdentifier,
                   let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
                    let appInfo = _ApplicationInfo(
                        appName: appName,
                        packageName: appId,
                        versionName: appVersion,
                        buildType: "release",
                        launchCount: 1
                    )
                    updateUserWithApplicationInfo(appInfo)
                }
            }
        } else {
            logger.debug("Auto environment attributes disabled, skipping device and application info detection")
        }
        
        // Set up connection status monitoring
        setupConnectionStatusMonitoring()
        
        // Set up background state monitoring
        setupBackgroundStateMonitoring()
        
        // Add user context from the main user object
        addMainUserContext()
        
        // Start periodic SDK settings check
        startPeriodicSdkSettingsCheck()
        
        // Initial fetch of SDK settings
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.checkSdkSettings()
                self.sdkSettingsSemaphore.signal()
            } catch {
                self.logger.error("Error in initial SDK settings check: \(error)")
                self.sdkSettingsSemaphore.signal() // Signal anyway to avoid blocking
            }
        }
    }
    
    /// Set up connection status monitoring
    private func setupConnectionStatusMonitoring() {
        connectionManager.addConnectionStatusListener { [weak self] newStatus, info in
            guard let self = self else { return }
            
            self.logger.debug("Connection status changed: \(newStatus)")
            
            // Notify all listeners
            for listener in self.connectionStatusListeners {
                listener.onConnectionStatusChanged(newStatus: newStatus, info: info)
            }
            
            // If we're connected and we were previously disconnected, try to sync
            if newStatus == .connected &&
                (info.lastSuccessfulConnectionTimeMs == 0 ||
                 UInt64(Date().timeIntervalSince1970 * 1000) - info.lastSuccessfulConnectionTimeMs > 60000) {
                
                DispatchQueue.global(qos: .background).async {
                    do {
                        try self.checkSdkSettings()
                    } catch {
                        self.logger.error("Error checking SDK settings: \(error)")
                    }
                }
            }
        }
    }
    
    /// Set up background state monitoring
    private func setupBackgroundStateMonitoring() {
        backgroundStateMonitor.addAppStateListener { [weak self] state in
            guard let self = self else { return }
            
            self.logger.debug("App state changed: \(state)")
            
            if state == .background && self.config.disableBackgroundPolling {
                // Pause polling in background if configured to do so
                self.pausePolling()
            } else if state == .foreground {
                // Resume polling when app comes to foreground
                self.resumePolling()
                
                // Check for updates immediately when coming to foreground
                DispatchQueue.global(qos: .background).async {
                    do {
                        try self.checkSdkSettings()
                    } catch {
                        self.logger.error("Error checking SDK settings: \(error)")
                    }
                }
            }
        }
        
        backgroundStateMonitor.addBatteryStateListener { [weak self] state in
            guard let self = self else { return }
            
            self.logger.debug("Battery state changed: low=\(state.isLow), charging=\(state.isCharging), level=\(state.level)")
            
            if self.config.useReducedPollingWhenBatteryLow && state.isLow && !state.isCharging {
                // Use reduced polling on low battery
                self.adjustPollingForBatteryState(useLowBatteryInterval: true)
            } else {
                // Use normal polling
                self.adjustPollingForBatteryState(useLowBatteryInterval: false)
            }
        }
    }
    
    /// Update user with device context
    private func updateUserWithDeviceContext() {
        user.setDeviceContext(deviceContext)
    }
    
    /// Update user with application info
    private func updateUserWithApplicationInfo(_ appInfo: _ApplicationInfo) {
        applicationInfo = appInfo
        user.setApplicationInfo(appInfo)
    }
    
    /// Add the main user context
    private func addMainUserContext() {
        // Create a user context from the main user object
        let userContext = EvaluationContext(
            type: .user,
            key: user.userCustomerId ?? UUID().uuidString,
            properties: user.properties
        )
        
        contexts["user"] = userContext
        
        // Add user context to user properties
        user.addContext(userContext)
        
        // Add device context to user properties
        updateUserWithDeviceContext()
    }
    
    /// Pause polling when in background if configured
    private func pausePolling() {
        if config.disableBackgroundPolling {
            logger.debug("Pausing polling in background")
            
            timerMutex.lock()
            defer { timerMutex.unlock() }
            
            if let timer = sdkSettingsTimer {
                timer.cancel()
                sdkSettingsTimer = nil
            }
        }
    }
    
    /// Resume polling when returning to foreground
    private func resumePolling() {
        logger.debug("Resuming polling")
        
        restartPeriodicSdkSettingsCheck()
    }
    
    /// Adjust polling intervals based on battery state
    private func adjustPollingForBatteryState(useLowBatteryInterval: Bool) {
        if backgroundStateMonitor.getCurrentAppState() == .background {
            let interval = useLowBatteryInterval ?
                config.reducedPollingIntervalMs :
                config.backgroundPollingIntervalMs
            
            logger.debug("Adjusting background polling interval to \(interval) ms due to battery state")
            
            restartPeriodicSdkSettingsCheck(customIntervalMs: interval)
        }
    }
    
    /// Start periodic SDK settings check
    private func startPeriodicSdkSettingsCheck() {
        restartPeriodicSdkSettingsCheck()
    }
    
    /// Restart periodic SDK settings check
    private func restartPeriodicSdkSettingsCheck(customIntervalMs: TimeInterval? = nil) {
        timerMutex.lock()
        defer { timerMutex.unlock() }
        
        // Cancel existing timer if any
        if let timer = sdkSettingsTimer {
            timer.cancel()
            sdkSettingsTimer = nil
        }
        
        // Create a new timer
        let intervalMs = customIntervalMs ?? config.sdkSettingsCheckIntervalMs
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        
        timer.schedule(deadline: .now() + intervalMs / 1000.0,
                      repeating: intervalMs / 1000.0)
        
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.checkSdkSettings()
            } catch {
                self.logger.error("Error checking SDK settings: \(error)")
            }
        }
        
        sdkSettingsTimer = timer
        timer.resume()
    }
    
    /// Check SDK settings
    /// - Throws: An error if the settings could not be fetched
    private func checkSdkSettings() throws {
        // Implementation
    }
    
    /// Add a connection status listener
    /// - Parameter listener: The listener to add
    public func addConnectionStatusListener(_ listener: ConnectionStatusListener) {
        connectionStatusListeners.append(listener)
    }
    
    /// Remove a connection status listener
    /// - Parameter listener: The listener to remove
    public func removeConnectionStatusListener(_ listener: ConnectionStatusListener) {
        connectionStatusListeners.removeAll(where: { $0 === listener })
    }
    
    /// Add a listener for a specific feature flag
    /// - Parameters:
    ///   - key: The feature flag key
    ///   - listener: Callback function invoked whenever the flag value changes
    public func addConfigListener<T>(_ key: String, listener: @escaping (T) -> Void) {
        configMutex.lock()
        defer { configMutex.unlock() }
        
        if configListeners[key] == nil {
            configListeners[key] = []
        }
        
        configListeners[key]?.append { (value) in
            if let typedValue = value as? T {
                listener(typedValue)
            }
        }
        
        logger.debug("Added listener for key: \(key)")
    }
    
    /// Remove a listener for a specific feature flag
    /// - Parameters:
    ///   - key: The feature flag key
    ///   - listener: The listener to remove
    public func removeConfigListener<T>(_ key: String, listener: @escaping (T) -> Void) {
        // Note: In a real implementation, this would need to handle identity comparison of closures,
        // which is tricky in Swift. For now, we just clear all listeners for the key.
        clearConfigListeners(key)
    }
    
    /// Remove all listeners for a specific feature flag
    /// - Parameter key: The feature flag key
    public func clearConfigListeners(_ key: String) {
        configMutex.lock()
        defer { configMutex.unlock() }
        
        configListeners.removeValue(forKey: key)
        logger.debug("Cleared all listeners for key: \(key)")
    }
    
    /// Get a string value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    /// - Returns: The value for the key, or the fallback value if not found
    public func getString(_ key: String, fallbackValue: String) -> String {
        return getConfigValue(key, fallbackValue: fallbackValue) { $0 is String }
    }
    
    /// Get a string value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    ///   - callback: A callback function to invoke with the value
    /// - Returns: The value for the key, or the fallback value if not found
    public func getString(_ key: String, fallbackValue: String, callback: ((String) -> Void)? = nil) -> String {
        let value = getString(key, fallbackValue: fallbackValue)
        callback?(value)
        return value
    }
    
    /// Get a number value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    /// - Returns: The value for the key, or the fallback value if not found
    public func getNumber(_ key: String, fallbackValue: NSNumber) -> NSNumber {
        return getConfigValue(key, fallbackValue: fallbackValue) { $0 is NSNumber }
    }
    
    /// Get a number value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    ///   - callback: A callback function to invoke with the value
    /// - Returns: The value for the key, or the fallback value if not found
    public func getNumber(_ key: String, fallbackValue: NSNumber, callback: ((NSNumber) -> Void)? = nil) -> NSNumber {
        let value = getNumber(key, fallbackValue: fallbackValue)
        callback?(value)
        return value
    }
    
    /// Get a boolean value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    /// - Returns: The value for the key, or the fallback value if not found
    public func getBoolean(_ key: String, fallbackValue: Bool) -> Bool {
        return getConfigValue(key, fallbackValue: fallbackValue) { $0 is Bool }
    }
    
    /// Get a boolean value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    ///   - callback: A callback function to invoke with the value
    /// - Returns: The value for the key, or the fallback value if not found
    public func getBoolean(_ key: String, fallbackValue: Bool, callback: ((Bool) -> Void)? = nil) -> Bool {
        let value = getBoolean(key, fallbackValue: fallbackValue)
        callback?(value)
        return value
    }
    
    /// Get a value from the configuration
    /// - Parameters:
    ///   - key: The key to get
    ///   - fallbackValue: The value to return if the key is not found
    ///   - typeCheck: A function to check if the value is of the correct type
    /// - Returns: The value for the key, or the fallback value if not found
    private func getConfigValue<T>(_ key: String, fallbackValue: T, typeCheck: (Any) -> Bool) -> T {
        configMutex.lock()
        defer { configMutex.unlock() }
        
        guard let value = configMap[key] else {
            return fallbackValue
        }
        
        guard typeCheck(value) else {
            logger.warning("Value for key \(key) is not of expected type")
            return fallbackValue
        }
        
        return value as! T
    }
    
    /// Create a new CFClient
    /// - Parameters:
    ///   - config: The configuration for the client
    ///   - user: The user for whom to evaluate feature flags
    /// - Returns: A new CFClient instance
    public static func create(config: CFConfig, user: CFUser) -> _CFClient {
        return _CFClient(config: config, user: user)
    }
} 