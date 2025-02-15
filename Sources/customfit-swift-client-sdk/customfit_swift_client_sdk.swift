public struct CustomFitClient {
    
    private let token: String
    
    public init(token: String) {
        self.token = token
        print("CustomFitClient initialized with token: \(token)")
    }
    
    /// Returns a dummy flag value for a given key.
    /// In the future, you can replace with real logic (e.g., network call).
    public func getFlagValue(key: String, defaultValue: String) -> String {
        return "mocked-value-for-\(key)"
    }
}
