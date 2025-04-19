import Foundation

/// Represents device and operating system information for context-aware evaluation.
public struct _DeviceContext: Codable {
    /// Device manufacturer
    public let manufacturer: String?
    
    /// Device model
    public let model: String?
    
    /// Operating system name (e.g., "iOS", "macOS")
    public let osName: String?
    
    /// Operating system version
    public let osVersion: String?
    
    /// SDK version
    public let sdkVersion: String
    
    /// Application identifier
    public let appId: String?
    
    /// Application version
    public let appVersion: String?
    
    /// Device locale
    public let locale: String?
    
    /// Device timezone
    public let timezone: String?
    
    /// Device screen width in pixels
    public let screenWidth: Int?
    
    /// Device screen height in pixels
    public let screenHeight: Int?
    
    /// Device screen density (DPI)
    public let screenDensity: Float?
    
    /// Network type (e.g., "wifi", "cellular")
    public let networkType: String?
    
    /// Additional custom attributes
    public let customAttributes: [String: String]
    
    /// Initialize a new device context
    /// - Parameters:
    ///   - manufacturer: Device manufacturer
    ///   - model: Device model
    ///   - osName: Operating system name
    ///   - osVersion: Operating system version
    ///   - sdkVersion: SDK version
    ///   - appId: Application identifier
    ///   - appVersion: Application version
    ///   - locale: Device locale
    ///   - timezone: Device timezone
    ///   - screenWidth: Device screen width in pixels
    ///   - screenHeight: Device screen height in pixels
    ///   - screenDensity: Device screen density (DPI)
    ///   - networkType: Network type
    ///   - customAttributes: Additional custom attributes
    public init(
        manufacturer: String? = nil,
        model: String? = nil,
        osName: String? = nil,
        osVersion: String? = nil,
        sdkVersion: String = "1.0.0",
        appId: String? = nil,
        appVersion: String? = nil,
        locale: String? = Locale.current.identifier,
        timezone: String? = TimeZone.current.identifier,
        screenWidth: Int? = nil,
        screenHeight: Int? = nil,
        screenDensity: Float? = nil,
        networkType: String? = nil,
        customAttributes: [String: String] = [:]
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.osName = osName
        self.osVersion = osVersion
        self.sdkVersion = sdkVersion
        self.appId = appId
        self.appVersion = appVersion
        self.locale = locale
        self.timezone = timezone
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.screenDensity = screenDensity
        self.networkType = networkType
        self.customAttributes = customAttributes
    }
    
    /// Creates a basic device context with system properties
    /// - Returns: A new device context with basic system information
    public static func createBasic() -> _DeviceContext {
        #if os(iOS)
        let osName = "iOS"
        #elseif os(macOS)
        let osName = "macOS"
        #elseif os(watchOS)
        let osName = "watchOS"
        #elseif os(tvOS)
        let osName = "tvOS"
        #else
        let osName = "unknown"
        #endif
        
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        return _DeviceContext(
            osName: osName,
            osVersion: osVersion,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }
    
    /// Creates a DeviceContext from a dictionary representation
    /// - Parameter dict: The dictionary containing device context data
    /// - Returns: A new device context, or nil if the dictionary is invalid
    public static func fromDict(_ dict: [String: Any]) -> _DeviceContext {
        return _DeviceContext(
            manufacturer: dict["manufacturer"] as? String,
            model: dict["model"] as? String,
            osName: dict["os_name"] as? String,
            osVersion: dict["os_version"] as? String,
            sdkVersion: (dict["sdk_version"] as? String) ?? "1.0.0",
            appId: dict["app_id"] as? String,
            appVersion: dict["app_version"] as? String,
            locale: dict["locale"] as? String,
            timezone: dict["timezone"] as? String,
            screenWidth: dict["screen_width"] as? Int,
            screenHeight: dict["screen_height"] as? Int,
            screenDensity: dict["screen_density"] as? Float,
            networkType: dict["network_type"] as? String,
            customAttributes: (dict["custom_attributes"] as? [String: String]) ?? [:]
        )
    }
    
    /// Converts the device context to a dictionary for sending to the API
    /// - Returns: Dictionary representation of the device context
    public func toDict() -> [String: Any?] {
        var dict: [String: Any?] = [
            "manufacturer": manufacturer,
            "model": model,
            "os_name": osName,
            "os_version": osVersion,
            "sdk_version": sdkVersion,
            "app_id": appId,
            "app_version": appVersion,
            "locale": locale,
            "timezone": timezone,
            "screen_width": screenWidth,
            "screen_height": screenHeight,
            "screen_density": screenDensity,
            "network_type": networkType
        ]
        
        if !customAttributes.isEmpty {
            dict["custom_attributes"] = customAttributes
        }
        
        return dict.compactMapValues { $0 }
    }
    
    /// Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case manufacturer
        case model
        case osName = "os_name"
        case osVersion = "os_version"
        case sdkVersion = "sdk_version"
        case appId = "app_id"
        case appVersion = "app_version"
        case locale
        case timezone
        case screenWidth = "screen_width"
        case screenHeight = "screen_height"
        case screenDensity = "screen_density"
        case networkType = "network_type"
        case customAttributes = "custom_attributes"
    }
    
    /// Builder for creating DeviceContext instances
    public class Builder {
        private var manufacturer: String?
        private var model: String?
        private var osName: String?
        private var osVersion: String?
        private var sdkVersion: String = "1.0.0"
        private var appId: String?
        private var appVersion: String?
        private var locale: String? = Locale.current.identifier
        private var timezone: String? = TimeZone.current.identifier
        private var screenWidth: Int?
        private var screenHeight: Int?
        private var screenDensity: Float?
        private var networkType: String?
        private var customAttributes: [String: String] = [:]
        
        /// Initialize a new builder
        public init() {
            #if os(iOS)
            self.osName = "iOS"
            #elseif os(macOS)
            self.osName = "macOS"
            #elseif os(watchOS)
            self.osName = "watchOS"
            #elseif os(tvOS)
            self.osName = "tvOS"
            #else
            self.osName = "unknown"
            #endif
            
            self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        }
        
        /// Set the device manufacturer
        /// - Parameter manufacturer: The manufacturer
        /// - Returns: The builder instance
        public func manufacturer(_ manufacturer: String) -> Builder {
            self.manufacturer = manufacturer
            return self
        }
        
        /// Set the device model
        /// - Parameter model: The model
        /// - Returns: The builder instance
        public func model(_ model: String) -> Builder {
            self.model = model
            return self
        }
        
        /// Set the operating system name
        /// - Parameter osName: The operating system name
        /// - Returns: The builder instance
        public func osName(_ osName: String) -> Builder {
            self.osName = osName
            return self
        }
        
        /// Set the operating system version
        /// - Parameter osVersion: The operating system version
        /// - Returns: The builder instance
        public func osVersion(_ osVersion: String) -> Builder {
            self.osVersion = osVersion
            return self
        }
        
        /// Set the SDK version
        /// - Parameter sdkVersion: The SDK version
        /// - Returns: The builder instance
        public func sdkVersion(_ sdkVersion: String) -> Builder {
            self.sdkVersion = sdkVersion
            return self
        }
        
        /// Set the application identifier
        /// - Parameter appId: The application identifier
        /// - Returns: The builder instance
        public func appId(_ appId: String) -> Builder {
            self.appId = appId
            return self
        }
        
        /// Set the application version
        /// - Parameter appVersion: The application version
        /// - Returns: The builder instance
        public func appVersion(_ appVersion: String) -> Builder {
            self.appVersion = appVersion
            return self
        }
        
        /// Set the device locale
        /// - Parameter locale: The locale
        /// - Returns: The builder instance
        public func locale(_ locale: String) -> Builder {
            self.locale = locale
            return self
        }
        
        /// Set the device timezone
        /// - Parameter timezone: The timezone
        /// - Returns: The builder instance
        public func timezone(_ timezone: String) -> Builder {
            self.timezone = timezone
            return self
        }
        
        /// Set the screen width
        /// - Parameter screenWidth: The screen width in pixels
        /// - Returns: The builder instance
        public func screenWidth(_ screenWidth: Int) -> Builder {
            self.screenWidth = screenWidth
            return self
        }
        
        /// Set the screen height
        /// - Parameter screenHeight: The screen height in pixels
        /// - Returns: The builder instance
        public func screenHeight(_ screenHeight: Int) -> Builder {
            self.screenHeight = screenHeight
            return self
        }
        
        /// Set the screen density
        /// - Parameter screenDensity: The screen density in DPI
        /// - Returns: The builder instance
        public func screenDensity(_ screenDensity: Float) -> Builder {
            self.screenDensity = screenDensity
            return self
        }
        
        /// Set the network type
        /// - Parameter networkType: The network type
        /// - Returns: The builder instance
        public func networkType(_ networkType: String) -> Builder {
            self.networkType = networkType
            return self
        }
        
        /// Add a custom attribute
        /// - Parameters:
        ///   - key: The attribute key
        ///   - value: The attribute value
        /// - Returns: The builder instance
        public func addCustomAttribute(key: String, value: String) -> Builder {
            self.customAttributes[key] = value
            return self
        }
        
        /// Add multiple custom attributes
        /// - Parameter attributes: The attributes to add
        /// - Returns: The builder instance
        public func addCustomAttributes(_ attributes: [String: String]) -> Builder {
            self.customAttributes.merge(attributes) { (_, new) in new }
            return self
        }
        
        /// Build the device context
        /// - Returns: A new DeviceContext instance
        public func build() -> _DeviceContext {
            return _DeviceContext(
                manufacturer: manufacturer,
                model: model,
                osName: osName,
                osVersion: osVersion,
                sdkVersion: sdkVersion,
                appId: appId,
                appVersion: appVersion,
                locale: locale,
                timezone: timezone,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                screenDensity: screenDensity,
                networkType: networkType,
                customAttributes: customAttributes
            )
        }
    }
} 