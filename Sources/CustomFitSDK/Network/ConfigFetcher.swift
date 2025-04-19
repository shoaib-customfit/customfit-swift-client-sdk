import Foundation
import Logging

/// Fetches configurations from the CustomFit API
public class ConfigFetcher {
    /// The HTTP client for making requests
    private let httpClient: HttpClient
    
    /// The configuration for the client
    private let config: CFConfig
    
    /// The user for whom to fetch configurations
    private let user: CFUser
    
    /// Whether the fetcher is in offline mode
    private var offlineMode: Bool
    
    /// Logger
    private let logger = Logger(label: "customfit.ConfigFetcher")
    
    /// Initialize a new config fetcher
    /// - Parameters:
    ///   - httpClient: The HTTP client to use for requests
    ///   - config: The configuration for the client
    ///   - user: The user for whom to fetch configurations
    public init(httpClient: HttpClient, config: CFConfig, user: CFUser) {
        self.httpClient = httpClient
        self.config = config
        self.user = user
        self.offlineMode = config.offlineMode
    }
    
    /// Set the offline mode
    /// - Parameter offlineMode: Whether the fetcher should be in offline mode
    public func setOffline(_ offlineMode: Bool) {
        self.offlineMode = offlineMode
    }
    
    /// Fetch the latest settings from the API
    /// - Parameters:
    ///   - previousLastModified: The last modified timestamp from the previous fetch
    ///   - completion: A callback to invoke with the result
    public func fetchSettings(previousLastModified: String? = nil, completion: @escaping (Result<(Data, String?), Error>) -> Void) {
        if offlineMode {
            logger.warning("Cannot fetch settings in offline mode")
            completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot fetch settings in offline mode"])))
            return
        }
        
        // Construct the URL for the API request
        guard let apiUrl = createSettingsUrl() else {
            logger.error("Failed to create settings URL")
            completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create settings URL"])))
            return
        }
        
        // Set up the request headers
        var headers = ["Authorization": "Bearer \(config.clientKey)"]
        
        // Add If-Modified-Since header if we have a previous last modified timestamp
        if let previousLastModified = previousLastModified {
            headers["If-Modified-Since"] = previousLastModified
        }
        
        // Make the request
        httpClient.get(url: apiUrl, headers: headers) { result in
            switch result {
            case .success(let data):
                // Extract the Last-Modified header from the response
                // Note: In a real implementation, we would need access to the response headers
                // For now, we'll return nil for the last modified timestamp
                completion(.success((data, nil)))
                
            case .failure(let error):
                // Check if the error is a 304 Not Modified
                let nsError = error as NSError
                if nsError.code == 304 {
                    // If the resource hasn't been modified, we can use the cached version
                    self.logger.info("Settings not modified since last fetch")
                    completion(.success((Data(), previousLastModified)))
                } else {
                    self.logger.error("Failed to fetch settings: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Create the URL for the settings API request
    /// - Returns: The URL, or nil if it couldn't be created
    private func createSettingsUrl() -> URL? {
        // In a real implementation, this would construct the URL with query parameters
        // For example, it might include the dimension ID and user details
        
        let baseUrl = "https://api.customfit.ai/v1/settings"
        
        guard var components = URLComponents(string: baseUrl) else {
            return nil
        }
        
        // Add query parameters
        var queryItems: [URLQueryItem] = []
        
        if let dimensionId = config.dimensionId {
            queryItems.append(URLQueryItem(name: "dimension_id", value: dimensionId))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url
    }
    
    /// Evaluate configurations for a specific dimension
    /// - Parameters:
    ///   - dimensionId: The dimension ID
    ///   - completion: A callback to invoke with the result
    public func evaluateConfigs(dimensionId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        if offlineMode {
            logger.warning("Cannot evaluate configs in offline mode")
            completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot evaluate configs in offline mode"])))
            return
        }
        
        // Construct the URL for the API request
        guard let apiUrl = createEvaluateUrl(dimensionId: dimensionId) else {
            logger.error("Failed to create evaluate URL")
            completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create evaluate URL"])))
            return
        }
        
        // Create the request body
        guard let body = createEvaluateRequestBody() else {
            logger.error("Failed to create evaluate request body")
            completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create evaluate request body"])))
            return
        }
        
        // Set up the request headers
        let headers = [
            "Authorization": "Bearer \(config.clientKey)",
            "Content-Type": "application/json"
        ]
        
        // Make the request
        httpClient.post(url: apiUrl, body: body, headers: headers) { result in
            switch result {
            case .success(let data):
                do {
                    // Parse the JSON response
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response as JSON object"])
                    }
                    
                    completion(.success(jsonObject))
                } catch {
                    self.logger.error("Failed to parse evaluate response: \(error)")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self.logger.error("Failed to evaluate configs: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// Create the URL for the evaluate API request
    /// - Parameter dimensionId: The dimension ID
    /// - Returns: The URL, or nil if it couldn't be created
    private func createEvaluateUrl(dimensionId: String) -> URL? {
        let baseUrl = "https://api.customfit.ai/v1/evaluate"
        
        guard var components = URLComponents(string: baseUrl) else {
            return nil
        }
        
        // Add query parameters
        let queryItems = [URLQueryItem(name: "dimension_id", value: dimensionId)]
        components.queryItems = queryItems
        
        return components.url
    }
    
    /// Create the request body for the evaluate API request
    /// - Returns: The request body as Data, or nil if it couldn't be created
    private func createEvaluateRequestBody() -> Data? {
        // Create a dictionary with the user's properties
        let body = user.toUserDict()
        
        do {
            // Convert the dictionary to JSON data
            return try JSONSerialization.data(withJSONObject: body)
        } catch {
            logger.error("Failed to serialize user properties: \(error)")
            return nil
        }
    }
} 