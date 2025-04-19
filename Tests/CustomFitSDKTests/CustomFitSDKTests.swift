import XCTest
@testable import CustomFitSDK

final class CustomFitSDKTests: XCTestCase {
    func testSDKInitialization() throws {
        // Create a configuration
        let config = CFConfig(clientKey: "test_client_key")
        
        // Create a user
        let user = CFUser(
            userCustomerId: "test_user_id",
            anonymous: false
        )
        
        // Initialize the SDK
        let client = CustomFitSDK.initialize(with: config, user: user)
        
        // Verify the client is not nil
        XCTAssertNotNil(client)
    }
    
    func testGetStringFlag() throws {
        // Create a configuration
        let config = CFConfig(clientKey: "test_client_key")
        
        // Create a user
        let user = CFUser(
            userCustomerId: "test_user_id",
            anonymous: false
        )
        
        // Initialize the SDK
        let client = CustomFitSDK.initialize(with: config, user: user)
        
        // Get a string flag
        let flagValue = client.getString("test_flag", fallbackValue: "default_value")
        
        // Verify the flag value is the default value (since we're not connected to a real API)
        XCTAssertEqual(flagValue, "default_value")
    }
    
    func testGetBooleanFlag() throws {
        // Create a configuration
        let config = CFConfig(clientKey: "test_client_key")
        
        // Create a user
        let user = CFUser(
            userCustomerId: "test_user_id",
            anonymous: false
        )
        
        // Initialize the SDK
        let client = CustomFitSDK.initialize(with: config, user: user)
        
        // Get a boolean flag
        let flagValue = client.getBoolean("test_flag", fallbackValue: true)
        
        // Verify the flag value is the default value (since we're not connected to a real API)
        XCTAssertTrue(flagValue)
    }
    
    func testAddConfigListener() throws {
        // Create a configuration
        let config = CFConfig(clientKey: "test_client_key")
        
        // Create a user
        let user = CFUser(
            userCustomerId: "test_user_id",
            anonymous: false
        )
        
        // Initialize the SDK
        let client = CustomFitSDK.initialize(with: config, user: user)
        
        // Create an expectation for the listener
        let expectation = XCTestExpectation(description: "Config listener called")
        
        // Add a config listener
        client.addConfigListener("test_flag") { (value: String) in
            // This won't actually be called in our test since we're not updating any flags
            expectation.fulfill()
        }
        
        // We can't really test the listener being called without mocking the internals,
        // so we'll just verify that adding the listener doesn't crash
        
        // For a more complete test, we would need to mock the internal state and force a flag update
    }
    
    func testUserProperties() throws {
        // Create a user
        let user = CFUser(
            userCustomerId: "test_user_id",
            anonymous: false
        )
        
        // Add some properties
        user.addProperty(key: "test_property", value: "test_value")
        user.addProperties(["another_property": 123])
        
        // Verify the properties are there
        let properties = user.getCurrentProperties()
        XCTAssertEqual(properties["test_property"] as? String, "test_value")
        XCTAssertEqual(properties["another_property"] as? Int, 123)
    }
    
    func testDeviceContext() throws {
        // Create a device context
        let deviceContext = DeviceContext.createBasic()
        
        // Verify it has some reasonable values
        XCTAssertNotNil(deviceContext.osName)
        XCTAssertNotNil(deviceContext.locale)
        XCTAssertNotNil(deviceContext.timezone)
    }
    
    func testApplicationInfo() throws {
        // Create an application info
        let appInfo = ApplicationInfo(
            appName: "Test App",
            packageName: "com.example.test",
            versionName: "1.0.0",
            versionCode: 1,
            buildType: "debug",
            launchCount: 1
        )
        
        // Create a copy with updated launch count
        let updatedAppInfo = appInfo.copyWith(launchCount: 2)
        
        // Verify the updated value
        XCTAssertEqual(updatedAppInfo.launchCount, 2)
        
        // Verify the other values are the same
        XCTAssertEqual(updatedAppInfo.appName, "Test App")
        XCTAssertEqual(updatedAppInfo.packageName, "com.example.test")
        XCTAssertEqual(updatedAppInfo.versionName, "1.0.0")
        XCTAssertEqual(updatedAppInfo.versionCode, 1)
        XCTAssertEqual(updatedAppInfo.buildType, "debug")
    }
    
    func testEventPropertiesBuilder() throws {
        // Create a builder
        let builder = EventPropertiesBuilder()
        
        // Add some properties
        let properties = builder
            .add(key: "property1", value: "value1")
            .add(key: "property2", value: 123)
            .addAll(properties: ["property3": true, "property4": ["nested": "value"]])
            .build()
        
        // Verify the properties are there
        XCTAssertEqual(properties["property1"] as? String, "value1")
        XCTAssertEqual(properties["property2"] as? Int, 123)
        XCTAssertEqual(properties["property3"] as? Bool, true)
        XCTAssertEqual((properties["property4"] as? [String: String])?["nested"], "value")
    }
} 