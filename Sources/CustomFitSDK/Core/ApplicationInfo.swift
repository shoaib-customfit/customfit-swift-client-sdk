import Foundation

/// Collects and stores information about the application
/// for use in targeting and analytics.
public struct _ApplicationInfo: Codable {
    /// Application name
    public let appName: String?
    
    /// Application package name/identifier
    public let packageName: String?
    
    /// Application version name (e.g., "1.2.3")
    public let versionName: String?
    
    /// Application version code (numeric)
    public let versionCode: Int?
    
    /// When the app was first installed
    public let installDate: String?
    
    /// When the app was last updated
    public let lastUpdateDate: String?
    
    /// Build type (e.g., "debug", "release")
    public let buildType: String?
    
    /// How many times the app has been launched
    public let launchCount: Int
    
    /// Additional custom attributes
    public let customAttributes: [String: String]
    
    /// Initialize a new application info
    /// - Parameters:
    ///   - appName: Application name
    ///   - packageName: Application package name/identifier
    ///   - versionName: Application version name (e.g., "1.2.3")
    ///   - versionCode: Application version code (numeric)
    ///   - installDate: When the app was first installed
    ///   - lastUpdateDate: When the app was last updated
    ///   - buildType: Build type (e.g., "debug", "release")
    ///   - launchCount: How many times the app has been launched
    ///   - customAttributes: Additional custom attributes
    public init(
        appName: String? = nil,
        packageName: String? = nil,
        versionName: String? = nil,
        versionCode: Int? = nil,
        installDate: String? = nil,
        lastUpdateDate: String? = nil,
        buildType: String? = nil,
        launchCount: Int = 1,
        customAttributes: [String: String] = [:]
    ) {
        self.appName = appName
        self.packageName = packageName
        self.versionName = versionName
        self.versionCode = versionCode
        self.installDate = installDate
        self.lastUpdateDate = lastUpdateDate
        self.buildType = buildType
        self.launchCount = launchCount
        self.customAttributes = customAttributes
    }
    
    /// Create a copy of this ApplicationInfo with updated values
    /// - Parameters:
    ///   - appName: Application name
    ///   - packageName: Application package name/identifier
    ///   - versionName: Application version name (e.g., "1.2.3")
    ///   - versionCode: Application version code (numeric)
    ///   - installDate: When the app was first installed
    ///   - lastUpdateDate: When the app was last updated
    ///   - buildType: Build type (e.g., "debug", "release")
    ///   - launchCount: How many times the app has been launched
    ///   - customAttributes: Additional custom attributes
    /// - Returns: A new ApplicationInfo instance with the specified changes
    public func copyWith(
        appName: String? = nil,
        packageName: String? = nil,
        versionName: String? = nil,
        versionCode: Int? = nil,
        installDate: String? = nil,
        lastUpdateDate: String? = nil,
        buildType: String? = nil,
        launchCount: Int? = nil,
        customAttributes: [String: String]? = nil
    ) -> _ApplicationInfo {
        return _ApplicationInfo(
            appName: appName ?? self.appName,
            packageName: packageName ?? self.packageName,
            versionName: versionName ?? self.versionName,
            versionCode: versionCode ?? self.versionCode,
            installDate: installDate ?? self.installDate,
            lastUpdateDate: lastUpdateDate ?? self.lastUpdateDate,
            buildType: buildType ?? self.buildType,
            launchCount: launchCount ?? self.launchCount,
            customAttributes: customAttributes ?? self.customAttributes
        )
    }
    
    /// Converts the application info to a dictionary for serialization
    /// - Returns: Dictionary representation of the application info
    public func toDict() -> [String: Any?] {
        var dict: [String: Any?] = [
            "app_name": appName,
            "package_name": packageName,
            "version_name": versionName,
            "version_code": versionCode,
            "install_date": installDate,
            "last_update_date": lastUpdateDate,
            "build_type": buildType,
            "launch_count": launchCount
        ]
        
        if !customAttributes.isEmpty {
            dict["custom_attributes"] = customAttributes
        }
        
        return dict.compactMapValues { $0 }
    }
    
    /// Creates an ApplicationInfo from a dictionary representation
    /// - Parameter dict: The dictionary containing application info data
    /// - Returns: A new application info, or nil if the dictionary is invalid
    public static func fromDict(_ dict: [String: Any]) -> _ApplicationInfo {
        return _ApplicationInfo(
            appName: dict["app_name"] as? String,
            packageName: dict["package_name"] as? String,
            versionName: dict["version_name"] as? String,
            versionCode: dict["version_code"] as? Int,
            installDate: dict["install_date"] as? String,
            lastUpdateDate: dict["last_update_date"] as? String,
            buildType: dict["build_type"] as? String,
            launchCount: (dict["launch_count"] as? Int) ?? 1,
            customAttributes: (dict["custom_attributes"] as? [String: String]) ?? [:]
        )
    }
    
    /// Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case packageName = "package_name"
        case versionName = "version_name"
        case versionCode = "version_code"
        case installDate = "install_date"
        case lastUpdateDate = "last_update_date"
        case buildType = "build_type"
        case launchCount = "launch_count"
        case customAttributes = "custom_attributes"
    }
    
    /// Builder for ApplicationInfo
    public class Builder {
        private var appName: String?
        private var packageName: String?
        private var versionName: String?
        private var versionCode: Int?
        private var installDate: String?
        private var lastUpdateDate: String?
        private var buildType: String?
        private var launchCount: Int = 1
        private var customAttributes: [String: String] = [:]
        
        /// Initialize a new builder
        public init() {}
        
        /// Set the application name
        /// - Parameter appName: The application name
        /// - Returns: The builder instance
        public func appName(_ appName: String) -> Builder {
            self.appName = appName
            return self
        }
        
        /// Set the package name/identifier
        /// - Parameter packageName: The package name
        /// - Returns: The builder instance
        public func packageName(_ packageName: String) -> Builder {
            self.packageName = packageName
            return self
        }
        
        /// Set the version name
        /// - Parameter versionName: The version name
        /// - Returns: The builder instance
        public func versionName(_ versionName: String) -> Builder {
            self.versionName = versionName
            return self
        }
        
        /// Set the version code
        /// - Parameter versionCode: The version code
        /// - Returns: The builder instance
        public func versionCode(_ versionCode: Int) -> Builder {
            self.versionCode = versionCode
            return self
        }
        
        /// Set the install date
        /// - Parameter installDate: The install date
        /// - Returns: The builder instance
        public func installDate(_ installDate: Date) -> Builder {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.installDate = formatter.string(from: installDate)
            return self
        }
        
        /// Set the last update date
        /// - Parameter lastUpdateDate: The last update date
        /// - Returns: The builder instance
        public func lastUpdateDate(_ lastUpdateDate: Date) -> Builder {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.lastUpdateDate = formatter.string(from: lastUpdateDate)
            return self
        }
        
        /// Set the build type
        /// - Parameter buildType: The build type
        /// - Returns: The builder instance
        public func buildType(_ buildType: String) -> Builder {
            self.buildType = buildType
            return self
        }
        
        /// Set the launch count
        /// - Parameter launchCount: The launch count
        /// - Returns: The builder instance
        public func launchCount(_ launchCount: Int) -> Builder {
            self.launchCount = launchCount
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
        
        /// Build the application info
        /// - Returns: A new ApplicationInfo instance
        public func build() -> _ApplicationInfo {
            return _ApplicationInfo(
                appName: appName,
                packageName: packageName,
                versionName: versionName,
                versionCode: versionCode,
                installDate: installDate,
                lastUpdateDate: lastUpdateDate,
                buildType: buildType,
                launchCount: launchCount,
                customAttributes: customAttributes
            )
        }
    }
} 