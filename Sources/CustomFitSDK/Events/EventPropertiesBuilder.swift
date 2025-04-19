import Foundation

/// Builder for event properties
public class EventPropertiesBuilder {
    /// The properties being built
    private var properties: [String: Any] = [:]
    
    /// Initialize a new event properties builder
    public init() {}
    
    /// Add a property
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The property value
    /// - Returns: The builder instance
    public func add(key: String, value: Any) -> EventPropertiesBuilder {
        properties[key] = value
        return self
    }
    
    /// Add multiple properties
    /// - Parameter properties: The properties to add
    /// - Returns: The builder instance
    public func addAll(properties: [String: Any]) -> EventPropertiesBuilder {
        self.properties.merge(properties) { (_, new) in new }
        return self
    }
    
    /// Build the properties
    /// - Returns: The built properties
    public func build() -> [String: Any] {
        return properties
    }
} 