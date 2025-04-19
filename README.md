# CustomFit Swift SDK

The CustomFit Swift SDK allows iOS and macOS developers to integrate feature flags, A/B testing, and experimentation into their applications.

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/customfit/customfit-swift-client-sdk.git", from: "1.0.0")
]
```

Or in Xcode:

1. Go to File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/customfit/customfit-swift-client-sdk.git`
3. Select the version you want to use

## Usage

### Initialize the SDK

```swift
import CustomFitSDK

// Create a configuration
let config = CFConfig(clientKey: "your_client_key")

// Create a user
let user = CFUser(userCustomerId: "user123", anonymous: false)

// Initialize the SDK
let client = CustomFitSDK.initialize(with: config, user: user)
```

### Feature Flags

```swift
// Get a boolean flag
let showFeature = client.getBoolean("show_new_feature", fallbackValue: false)

// Get a string flag
let buttonColor = client.getString("button_color", fallbackValue: "blue")

// Get a number flag
let maxItems = client.getNumber("max_items", fallbackValue: NSNumber(value: 10))

// Listen for flag changes
client.addConfigListener("show_new_feature") { (value: Bool) in
    // Update UI based on new flag value
    updateFeatureVisibility(value)
}
```

### User Properties

```swift
// Add user properties
user.addProperty(key: "subscription_level", value: "premium")
user.addProperty(key: "last_login", value: Date())

// Add multiple properties at once
user.addProperties([
    "language": "en",
    "theme": "dark"
])
```

### Device Context

```swift
// Get the device context
let deviceContext = DeviceContext.createBasic()

// Or create a custom device context
let customDeviceContext = DeviceContext.Builder()
    .manufacturer("Apple")
    .model("iPhone")
    .osName("iOS")
    .osVersion("15.0")
    .screenWidth(375)
    .screenHeight(812)
    .build()

// Add the device context to the user
user.setDeviceContext(customDeviceContext)
```

### Event Tracking

```swift
// Track an event
client.track(eventType: "button_click", properties: [
    "button_id": "submit",
    "page": "checkout"
])

// Use the EventPropertiesBuilder
let properties = EventPropertiesBuilder()
    .add(key: "button_id", value: "submit")
    .add(key: "page", value: "checkout")
    .build()

client.track(eventType: "button_click", properties: properties)
```

## Advanced Configuration

```swift
// Use the builder pattern for more configuration options
let config = CFConfig.Builder(clientKey: "your_client_key")
    .eventsQueueSize(200)
    .eventsFlushTimeSeconds(30)
    .loggingEnabled(true)
    .debugLoggingEnabled(true)
    .offlineMode(false)
    .autoEnvAttributesEnabled(true)
    .build()
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 