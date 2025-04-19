import Foundation

/// Represents a context type for evaluation
public enum ContextType: String, Codable {
    case user = "user"
    case device = "device"
    case session = "session"
    case organization = "organization"
    case custom = "custom"
}

/// An evaluation context that can be used for targeting
public struct EvaluationContext: Codable {
    /// The context type
    public let type: ContextType
    
    /// Key identifying this context
    public let key: String
    
    /// Name of this context (optional)
    public let name: String?
    
    /// Properties associated with this context
    public let properties: [String: Any]
    
    /// Private attributes that should not be sent to analytics
    public let privateAttributes: [String]
    
    /// Initialize a new evaluation context
    /// - Parameters:
    ///   - type: The context type
    ///   - key: Key identifying this context
    ///   - name: Name of this context (optional)
    ///   - properties: Properties associated with this context
    ///   - privateAttributes: Private attributes that should not be sent to analytics
    public init(
        type: ContextType,
        key: String,
        name: String? = nil,
        properties: [String: Any] = [:],
        privateAttributes: [String] = []
    ) {
        self.type = type
        self.key = key
        self.name = name
        self.properties = properties
        self.privateAttributes = privateAttributes
    }
    
    /// Convert to a dictionary for API requests
    /// - Returns: Dictionary representation of the context
    public func toDict() -> [String: Any?] {
        var dict: [String: Any?] = [
            "type": type.rawValue,
            "key": key,
            "name": name,
            "properties": properties
        ]
        
        if !privateAttributes.isEmpty {
            dict["private_attributes"] = privateAttributes
        }
        
        return dict.compactMapValues { $0 }
    }
    
    /// Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case type, key, name, properties, privateAttributes = "private_attributes"
    }
    
    /// Encode this context to an encoder
    /// - Parameter encoder: The encoder to encode to
    /// - Throws: An error if encoding fails
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        
        // Encode properties as JSON data
        let propertiesData = try JSONSerialization.data(withJSONObject: properties)
        let propertiesString = String(data: propertiesData, encoding: .utf8) ?? "{}"
        try container.encode(propertiesString, forKey: .properties)
        
        try container.encode(privateAttributes, forKey: .privateAttributes)
    }
    
    /// Initialize from a decoder
    /// - Parameter decoder: The decoder to decode from
    /// - Throws: An error if decoding fails
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ContextType.self, forKey: .type)
        key = try container.decode(String.self, forKey: .key)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        // Decode properties from JSON string
        let propertiesString = try container.decode(String.self, forKey: .properties)
        let propertiesData = propertiesString.data(using: .utf8) ?? "{}".data(using: .utf8)!
        
        if let propertiesDict = try JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
            properties = propertiesDict
        } else {
            properties = [:]
        }
        
        privateAttributes = try container.decodeIfPresent([String].self, forKey: .privateAttributes) ?? []
    }
    
    /// Builder for EvaluationContext
    public class Builder {
        private let type: ContextType
        private let key: String
        private var name: String?
        private var properties: [String: Any] = [:]
        private var privateAttributes: [String] = []
        
        /// Initialize a builder with the required properties
        /// - Parameters:
        ///   - type: The context type
        ///   - key: Key identifying this context
        public init(type: ContextType, key: String) {
            self.type = type
            self.key = key
        }
        
        /// Set the name of the context
        /// - Parameter name: The name
        /// - Returns: The builder instance
        public func withName(_ name: String) -> Builder {
            self.name = name
            return self
        }
        
        /// Add properties to the context
        /// - Parameter properties: The properties to add
        /// - Returns: The builder instance
        public func withProperties(_ properties: [String: Any]) -> Builder {
            self.properties.merge(properties) { (_, new) in new }
            return self
        }
        
        /// Add a single property to the context
        /// - Parameters:
        ///   - key: The property key
        ///   - value: The property value
        /// - Returns: The builder instance
        public func withProperty(key: String, value: Any) -> Builder {
            self.properties[key] = value
            return self
        }
        
        /// Add private attributes to the context
        /// - Parameter attributes: The attributes to add
        /// - Returns: The builder instance
        public func withPrivateAttributes(_ attributes: [String]) -> Builder {
            self.privateAttributes.append(contentsOf: attributes)
            return self
        }
        
        /// Add a single private attribute to the context
        /// - Parameter attribute: The attribute to add
        /// - Returns: The builder instance
        public func addPrivateAttribute(_ attribute: String) -> Builder {
            self.privateAttributes.append(attribute)
            return self
        }
        
        /// Build the evaluation context
        /// - Returns: A new EvaluationContext instance
        public func build() -> EvaluationContext {
            return EvaluationContext(
                type: type,
                key: key,
                name: name,
                properties: properties,
                privateAttributes: privateAttributes
            )
        }
    }
}

/// Request structure for private attributes
public struct PrivateAttributesRequest: Codable {
    public let attributes: [String]
    
    public init(attributes: [String] = []) {
        self.attributes = attributes
    }
}

/// Represents a user in the CustomFit system
public class _CFUser: Codable {
    /// The user's customer ID (optional)
    public let userCustomerId: String?
    
    /// Whether the user is anonymous
    public let anonymous: Bool
    
    /// Private fields that should not be sent to analytics
    public let privateFields: PrivateAttributesRequest?
    
    /// Session fields that should not be sent to analytics
    public let sessionFields: PrivateAttributesRequest?
    
    /// Properties associated with the user
    private var _properties: [String: Any]
    
    /// Initialize a new user
    /// - Parameters:
    ///   - userCustomerId: The user's customer ID (optional)
    ///   - anonymous: Whether the user is anonymous
    ///   - privateFields: Private fields that should not be sent to analytics
    ///   - sessionFields: Session fields that should not be sent to analytics
    ///   - properties: Properties associated with the user
    public init(
        userCustomerId: String? = nil,
        anonymous: Bool = true,
        privateFields: PrivateAttributesRequest? = PrivateAttributesRequest(),
        sessionFields: PrivateAttributesRequest? = PrivateAttributesRequest(),
        properties: [String: Any] = [:]
    ) {
        self.userCustomerId = userCustomerId
        self.anonymous = anonymous
        self.privateFields = privateFields
        self.sessionFields = sessionFields
        self._properties = properties
    }
    
    /// Properties associated with the user (read-only)
    public var properties: [String: Any] {
        return _properties
    }
    
    /// Add a property to the user
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The property value
    public func addProperty(key: String, value: Any) {
        _properties[key] = value
    }
    
    /// Add multiple properties to the user
    /// - Parameter properties: The properties to add
    public func addProperties(_ properties: [String: Any]) {
        _properties.merge(properties) { (_, new) in new }
    }
    
    /// Get the current properties including any updates
    /// - Returns: The current properties
    public func getCurrentProperties() -> [String: Any] {
        return _properties
    }
    
    /// Add an evaluation context to the properties
    /// - Parameter context: The context to add
    public func addContext(_ context: EvaluationContext) {
        var contexts = _properties["contexts"] as? [[String: Any?]] ?? []
        contexts.append(context.toDict())
        _properties["contexts"] = contexts
    }
    
    /// Get all evaluation contexts
    /// - Returns: The evaluation contexts
    public func getContexts() -> [EvaluationContext] {
        guard let contextsDict = _properties["contexts"] as? [[String: Any?]] else {
            return []
        }
        
        return contextsDict.compactMap { contextDict in
            guard let typeString = contextDict["type"] as? String,
                  let type = ContextType(rawValue: typeString),
                  let key = contextDict["key"] as? String else {
                return nil
            }
            
            let name = contextDict["name"] as? String
            let properties = contextDict["properties"] as? [String: Any] ?? [:]
            let privateAttributes = (contextDict["private_attributes"] as? [String]) ?? []
            
            return EvaluationContext(
                type: type,
                key: key,
                name: name,
                properties: properties,
                privateAttributes: privateAttributes
            )
        }
    }
    
    /// Add device context to the properties
    /// - Parameter device: The device context
    public func setDeviceContext(_ device: DeviceContext) {
        _properties["device"] = device.toDict()
    }
    
    /// Get device context from properties
    /// - Returns: The device context, or nil if not found
    public func getDeviceContext() -> DeviceContext? {
        guard let deviceDict = _properties["device"] as? [String: Any] else {
            return nil
        }
        
        return DeviceContext.fromDict(deviceDict)
    }
    
    /// Set application info in the properties
    /// - Parameter appInfo: The application info
    public func setApplicationInfo(_ appInfo: ApplicationInfo) {
        _properties["application"] = appInfo.toDict()
    }
    
    /// Get application info from properties
    /// - Returns: The application info, or nil if not found
    public func getApplicationInfo() -> ApplicationInfo? {
        guard let appInfoDict = _properties["application"] as? [String: Any] else {
            return nil
        }
        
        return ApplicationInfo.fromDict(appInfoDict)
    }
    
    /// Update application launch count
    public func incrementAppLaunchCount() {
        guard let appInfo = getApplicationInfo() else { return }
        
        let updatedAppInfo = appInfo.copyWith(launchCount: appInfo.launchCount + 1)
        setApplicationInfo(updatedAppInfo)
    }
    
    /// Convert user data to a dictionary for API requests
    /// - Returns: Dictionary representation of the user
    public func toUserDict() -> [String: Any?] {
        return [
            "user_customer_id": userCustomerId,
            "anonymous": anonymous,
            "private_fields": privateFields,
            "session_fields": sessionFields,
            "properties": getCurrentProperties()
        ]
    }
    
    /// Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case userCustomerId = "user_customer_id"
        case anonymous
        case privateFields = "private_fields"
        case sessionFields = "session_fields"
        case properties
    }
    
    /// Encode this user to an encoder
    /// - Parameter encoder: The encoder to encode to
    /// - Throws: An error if encoding fails
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userCustomerId, forKey: .userCustomerId)
        try container.encode(anonymous, forKey: .anonymous)
        try container.encode(privateFields, forKey: .privateFields)
        try container.encode(sessionFields, forKey: .sessionFields)
        
        // Encode properties as JSON data
        let propertiesData = try JSONSerialization.data(withJSONObject: _properties)
        let propertiesString = String(data: propertiesData, encoding: .utf8) ?? "{}"
        try container.encode(propertiesString, forKey: .properties)
    }
    
    /// Initialize from a decoder
    /// - Parameter decoder: The decoder to decode from
    /// - Throws: An error if decoding fails
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userCustomerId = try container.decodeIfPresent(String.self, forKey: .userCustomerId)
        anonymous = try container.decode(Bool.self, forKey: .anonymous)
        privateFields = try container.decodeIfPresent(PrivateAttributesRequest.self, forKey: .privateFields)
        sessionFields = try container.decodeIfPresent(PrivateAttributesRequest.self, forKey: .sessionFields)
        
        // Decode properties from JSON string
        let propertiesString = try container.decode(String.self, forKey: .properties)
        let propertiesData = propertiesString.data(using: .utf8) ?? "{}".data(using: .utf8)!
        
        if let propertiesDict = try JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
            _properties = propertiesDict
        } else {
            _properties = [:]
        }
    }
    
    /// Builder for _CFUser
    public class Builder {
        private var userCustomerId: String?
        private var anonymous: Bool = true
        private var privateFields: PrivateAttributesRequest?
        private var sessionFields: PrivateAttributesRequest?
        private var properties: [String: Any] = [:]
        
        /// Initialize a builder
        public init() {}
        
        /// Set the user's customer ID
        /// - Parameter id: The customer ID
        /// - Returns: The builder instance
        public func withUserCustomerId(_ id: String) -> Builder {
            self.userCustomerId = id
            self.anonymous = false
            return self
        }
        
        /// Set whether the user is anonymous
        /// - Parameter anonymous: Whether the user is anonymous
        /// - Returns: The builder instance
        public func withAnonymous(_ anonymous: Bool) -> Builder {
            self.anonymous = anonymous
            return self
        }
        
        /// Set the private fields
        /// - Parameter attributes: The private attributes
        /// - Returns: The builder instance
        public func withPrivateFields(_ attributes: [String]) -> Builder {
            self.privateFields = PrivateAttributesRequest(attributes: attributes)
            return self
        }
        
        /// Set the session fields
        /// - Parameter attributes: The session attributes
        /// - Returns: The builder instance
        public func withSessionFields(_ attributes: [String]) -> Builder {
            self.sessionFields = PrivateAttributesRequest(attributes: attributes)
            return self
        }
        
        /// Add properties to the user
        /// - Parameter properties: The properties to add
        /// - Returns: The builder instance
        public func withProperties(_ properties: [String: Any]) -> Builder {
            self.properties.merge(properties) { (_, new) in new }
            return self
        }
        
        /// Add a single property to the user
        /// - Parameters:
        ///   - key: The property key
        ///   - value: The property value
        /// - Returns: The builder instance
        public func withProperty(key: String, value: Any) -> Builder {
            self.properties[key] = value
            return self
        }
        
        /// Build the user
        /// - Returns: A new _CFUser instance
        public func build() -> _CFUser {
            return _CFUser(
                userCustomerId: userCustomerId,
                anonymous: anonymous,
                privateFields: privateFields,
                sessionFields: sessionFields,
                properties: properties
            )
        }
    }
} 