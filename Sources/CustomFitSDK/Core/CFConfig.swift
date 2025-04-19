import Foundation

/// Configuration for the CustomFit SDK
public struct _CFConfig: Codable {
    /// The client key used to authenticate with the CustomFit API
    public let clientKey: String
    
    // Event tracker configuration
    public let eventsQueueSize: Int
    public let eventsFlushTimeSeconds: Int
    public let eventsFlushIntervalMs: TimeInterval
    
    // Summary manager configuration
    public let summariesQueueSize: Int
    public let summariesFlushTimeSeconds: Int
    public let summariesFlushIntervalMs: TimeInterval
    
    // SDK settings check configuration
    public let sdkSettingsCheckIntervalMs: TimeInterval
    
    // Network configuration
    public let networkConnectionTimeoutMs: Int
    public let networkReadTimeoutMs: Int
    
    // Logging configuration
    public let loggingEnabled: Bool
    public let debugLoggingEnabled: Bool
    
    // Offline mode - when true, no network requests will be made
    public let offlineMode: Bool
    
    // Background operation settings
    public let disableBackgroundPolling: Bool
    public let backgroundPollingIntervalMs: TimeInterval
    public let useReducedPollingWhenBatteryLow: Bool
    public let reducedPollingIntervalMs: TimeInterval
    public let maxStoredEvents: Int
    
    // Auto environment attributes enabled - when true, automatically collect device and app info
    public let autoEnvAttributesEnabled: Bool
    
    /// The dimension ID extracted from the client key
    public var dimensionId: String? {
        Self.extractDimensionIdFromToken(clientKey)
    }
    
    /// Initialize a configuration with the given client key and default values
    /// - Parameter clientKey: The client key used to authenticate with the CustomFit API
    public init(clientKey: String) {
        self.init(
            clientKey: clientKey,
            eventsQueueSize: 100,
            eventsFlushTimeSeconds: 60,
            eventsFlushIntervalMs: 1000,
            summariesQueueSize: 100,
            summariesFlushTimeSeconds: 60,
            summariesFlushIntervalMs: 60_000,
            sdkSettingsCheckIntervalMs: 300_000,
            networkConnectionTimeoutMs: 10_000,
            networkReadTimeoutMs: 10_000,
            loggingEnabled: true,
            debugLoggingEnabled: false,
            offlineMode: false,
            disableBackgroundPolling: false,
            backgroundPollingIntervalMs: 3_600_000,
            useReducedPollingWhenBatteryLow: true,
            reducedPollingIntervalMs: 7_200_000,
            maxStoredEvents: 100,
            autoEnvAttributesEnabled: false
        )
    }
    
    /// Initialize a configuration with custom values
    public init(
        clientKey: String,
        eventsQueueSize: Int = 100,
        eventsFlushTimeSeconds: Int = 60,
        eventsFlushIntervalMs: TimeInterval = 1000,
        summariesQueueSize: Int = 100,
        summariesFlushTimeSeconds: Int = 60,
        summariesFlushIntervalMs: TimeInterval = 60_000,
        sdkSettingsCheckIntervalMs: TimeInterval = 300_000,
        networkConnectionTimeoutMs: Int = 10_000,
        networkReadTimeoutMs: Int = 10_000,
        loggingEnabled: Bool = true,
        debugLoggingEnabled: Bool = false,
        offlineMode: Bool = false,
        disableBackgroundPolling: Bool = false,
        backgroundPollingIntervalMs: TimeInterval = 3_600_000,
        useReducedPollingWhenBatteryLow: Bool = true,
        reducedPollingIntervalMs: TimeInterval = 7_200_000,
        maxStoredEvents: Int = 100,
        autoEnvAttributesEnabled: Bool = false
    ) {
        self.clientKey = clientKey
        self.eventsQueueSize = eventsQueueSize
        self.eventsFlushTimeSeconds = eventsFlushTimeSeconds
        self.eventsFlushIntervalMs = eventsFlushIntervalMs
        self.summariesQueueSize = summariesQueueSize
        self.summariesFlushTimeSeconds = summariesFlushTimeSeconds
        self.summariesFlushIntervalMs = summariesFlushIntervalMs
        self.sdkSettingsCheckIntervalMs = sdkSettingsCheckIntervalMs
        self.networkConnectionTimeoutMs = networkConnectionTimeoutMs
        self.networkReadTimeoutMs = networkReadTimeoutMs
        self.loggingEnabled = loggingEnabled
        self.debugLoggingEnabled = debugLoggingEnabled
        self.offlineMode = offlineMode
        self.disableBackgroundPolling = disableBackgroundPolling
        self.backgroundPollingIntervalMs = backgroundPollingIntervalMs
        self.useReducedPollingWhenBatteryLow = useReducedPollingWhenBatteryLow
        self.reducedPollingIntervalMs = reducedPollingIntervalMs
        self.maxStoredEvents = maxStoredEvents
        self.autoEnvAttributesEnabled = autoEnvAttributesEnabled
    }
    
    /// Extract the dimension ID from a JWT token
    /// - Parameter token: The JWT token
    /// - Returns: The dimension ID if it exists in the token, nil otherwise
    private static func extractDimensionIdFromToken(_ token: String) -> String? {
        do {
            let parts = token.split(separator: ".")
            guard parts.count == 3 else {
                print("Invalid JWT structure: \(token)")
                return nil
            }
            
            let payload = String(parts[1])
            let paddedPayload: String
            
            // Handle base64 padding
            let remainder = payload.count % 4
            if remainder > 0 {
                paddedPayload = payload + String(repeating: "=", count: 4 - remainder)
            } else {
                paddedPayload = payload
            }
            
            guard let decodedData = Data(base64Encoded: paddedPayload, options: .ignoreUnknownCharacters) else {
                print("Failed to decode JWT payload")
                return nil
            }
            
            guard let decodedString = String(data: decodedData, encoding: .utf8) else {
                print("Failed to convert JWT payload to string")
                return nil
            }
            
            guard let jsonData = decodedString.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("Failed to parse JWT payload as JSON")
                return nil
            }
            
            return jsonObject["dimension_id"] as? String
        } catch {
            print("JWT decoding error: \(error)")
            return nil
        }
    }
    
    /// A builder for configuring CFConfig instances
    public class Builder {
        private var clientKey: String
        private var eventsQueueSize: Int = 100
        private var eventsFlushTimeSeconds: Int = 60
        private var eventsFlushIntervalMs: TimeInterval = 1000
        private var summariesQueueSize: Int = 100
        private var summariesFlushTimeSeconds: Int = 60
        private var summariesFlushIntervalMs: TimeInterval = 60_000
        private var sdkSettingsCheckIntervalMs: TimeInterval = 300_000
        private var networkConnectionTimeoutMs: Int = 10_000
        private var networkReadTimeoutMs: Int = 10_000
        private var loggingEnabled: Bool = true
        private var debugLoggingEnabled: Bool = false
        private var offlineMode: Bool = false
        private var disableBackgroundPolling: Bool = false
        private var backgroundPollingIntervalMs: TimeInterval = 3_600_000
        private var useReducedPollingWhenBatteryLow: Bool = true
        private var reducedPollingIntervalMs: TimeInterval = 7_200_000
        private var maxStoredEvents: Int = 100
        private var autoEnvAttributesEnabled: Bool = false
        
        /// Initialize a builder with the given client key
        /// - Parameter clientKey: The client key used to authenticate with the CustomFit API
        public init(clientKey: String) {
            self.clientKey = clientKey
        }
        
        /// Set the events queue size
        /// - Parameter size: The maximum number of events to queue before flushing
        /// - Returns: The builder instance
        public func eventsQueueSize(_ size: Int) -> Builder {
            self.eventsQueueSize = size
            return self
        }
        
        /// Set the events flush time in seconds
        /// - Parameter seconds: The number of seconds to wait before flushing events
        /// - Returns: The builder instance
        public func eventsFlushTimeSeconds(_ seconds: Int) -> Builder {
            self.eventsFlushTimeSeconds = seconds
            return self
        }
        
        /// Set the events flush interval in milliseconds
        /// - Parameter ms: The interval in milliseconds to check for events to flush
        /// - Returns: The builder instance
        public func eventsFlushIntervalMs(_ ms: TimeInterval) -> Builder {
            self.eventsFlushIntervalMs = ms
            return self
        }
        
        /// Set the summaries queue size
        /// - Parameter size: The maximum number of summaries to queue before flushing
        /// - Returns: The builder instance
        public func summariesQueueSize(_ size: Int) -> Builder {
            self.summariesQueueSize = size
            return self
        }
        
        /// Set the summaries flush time in seconds
        /// - Parameter seconds: The number of seconds to wait before flushing summaries
        /// - Returns: The builder instance
        public func summariesFlushTimeSeconds(_ seconds: Int) -> Builder {
            self.summariesFlushTimeSeconds = seconds
            return self
        }
        
        /// Set the summaries flush interval in milliseconds
        /// - Parameter ms: The interval in milliseconds to check for summaries to flush
        /// - Returns: The builder instance
        public func summariesFlushIntervalMs(_ ms: TimeInterval) -> Builder {
            self.summariesFlushIntervalMs = ms
            return self
        }
        
        /// Set the SDK settings check interval in milliseconds
        /// - Parameter ms: The interval in milliseconds to check for SDK settings
        /// - Returns: The builder instance
        public func sdkSettingsCheckIntervalMs(_ ms: TimeInterval) -> Builder {
            self.sdkSettingsCheckIntervalMs = ms
            return self
        }
        
        /// Set the network connection timeout in milliseconds
        /// - Parameter ms: The timeout in milliseconds for network connections
        /// - Returns: The builder instance
        public func networkConnectionTimeoutMs(_ ms: Int) -> Builder {
            self.networkConnectionTimeoutMs = ms
            return self
        }
        
        /// Set the network read timeout in milliseconds
        /// - Parameter ms: The timeout in milliseconds for network reads
        /// - Returns: The builder instance
        public func networkReadTimeoutMs(_ ms: Int) -> Builder {
            self.networkReadTimeoutMs = ms
            return self
        }
        
        /// Set whether logging is enabled
        /// - Parameter enabled: Whether logging is enabled
        /// - Returns: The builder instance
        public func loggingEnabled(_ enabled: Bool) -> Builder {
            self.loggingEnabled = enabled
            return self
        }
        
        /// Set whether debug logging is enabled
        /// - Parameter enabled: Whether debug logging is enabled
        /// - Returns: The builder instance
        public func debugLoggingEnabled(_ enabled: Bool) -> Builder {
            self.debugLoggingEnabled = enabled
            return self
        }
        
        /// Set whether offline mode is enabled
        /// - Parameter enabled: Whether offline mode is enabled
        /// - Returns: The builder instance
        public func offlineMode(_ enabled: Bool) -> Builder {
            self.offlineMode = enabled
            return self
        }
        
        /// Set whether background polling is disabled
        /// - Parameter disabled: Whether background polling is disabled
        /// - Returns: The builder instance
        public func disableBackgroundPolling(_ disabled: Bool) -> Builder {
            self.disableBackgroundPolling = disabled
            return self
        }
        
        /// Set the background polling interval in milliseconds
        /// - Parameter ms: The interval in milliseconds for background polling
        /// - Returns: The builder instance
        public func backgroundPollingIntervalMs(_ ms: TimeInterval) -> Builder {
            precondition(ms > 0, "Interval must be greater than 0")
            self.backgroundPollingIntervalMs = ms
            return self
        }
        
        /// Set whether to use reduced polling when battery is low
        /// - Parameter useReduced: Whether to use reduced polling when battery is low
        /// - Returns: The builder instance
        public func useReducedPollingWhenBatteryLow(_ useReduced: Bool) -> Builder {
            self.useReducedPollingWhenBatteryLow = useReduced
            return self
        }
        
        /// Set the reduced polling interval in milliseconds
        /// - Parameter ms: The interval in milliseconds for reduced polling
        /// - Returns: The builder instance
        public func reducedPollingIntervalMs(_ ms: TimeInterval) -> Builder {
            precondition(ms > 0, "Interval must be greater than 0")
            self.reducedPollingIntervalMs = ms
            return self
        }
        
        /// Set the maximum number of events to store when offline
        /// - Parameter maxEvents: The maximum number of events to store
        /// - Returns: The builder instance
        public func maxStoredEvents(_ maxEvents: Int) -> Builder {
            precondition(maxEvents > 0, "Max stored events must be greater than 0")
            self.maxStoredEvents = maxEvents
            return self
        }
        
        /// Set whether auto environment attributes are enabled
        /// - Parameter enabled: Whether auto environment attributes are enabled
        /// - Returns: The builder instance
        public func autoEnvAttributesEnabled(_ enabled: Bool) -> Builder {
            self.autoEnvAttributesEnabled = enabled
            return self
        }
        
        /// Build the configuration
        /// - Returns: A new CFConfig instance
        public func build() -> _CFConfig {
            return _CFConfig(
                clientKey: clientKey,
                eventsQueueSize: eventsQueueSize,
                eventsFlushTimeSeconds: eventsFlushTimeSeconds,
                eventsFlushIntervalMs: eventsFlushIntervalMs,
                summariesQueueSize: summariesQueueSize,
                summariesFlushTimeSeconds: summariesFlushTimeSeconds,
                summariesFlushIntervalMs: summariesFlushIntervalMs,
                sdkSettingsCheckIntervalMs: sdkSettingsCheckIntervalMs,
                networkConnectionTimeoutMs: networkConnectionTimeoutMs,
                networkReadTimeoutMs: networkReadTimeoutMs,
                loggingEnabled: loggingEnabled,
                debugLoggingEnabled: debugLoggingEnabled,
                offlineMode: offlineMode,
                disableBackgroundPolling: disableBackgroundPolling,
                backgroundPollingIntervalMs: backgroundPollingIntervalMs,
                useReducedPollingWhenBatteryLow: useReducedPollingWhenBatteryLow,
                reducedPollingIntervalMs: reducedPollingIntervalMs,
                maxStoredEvents: maxStoredEvents,
                autoEnvAttributesEnabled: autoEnvAttributesEnabled
            )
        }
    }
} 