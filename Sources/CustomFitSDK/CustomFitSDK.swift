import Foundation

// Public re-exports - these should be internal types that are exported through this file
public typealias CFConfig = _CFConfig
public typealias CFUser = _CFUser
public typealias DeviceContext = _DeviceContext
public typealias ApplicationInfo = _ApplicationInfo
public typealias CFClient = _CFClient

/// The main entry point for the CustomFit SDK
public struct CustomFitSDK {
    /// The current version of the SDK
    public static let version = "1.0.0"
    
    /// Initialize the SDK with the given configuration
    /// - Parameter config: The configuration for the SDK
    /// - Parameter user: The user for whom to evaluate feature flags
    /// - Returns: A configured CFClient instance
    public static func initialize(with config: CFConfig, user: CFUser) -> CFClient {
        return CFClient.create(config: config, user: user)
    }
} 