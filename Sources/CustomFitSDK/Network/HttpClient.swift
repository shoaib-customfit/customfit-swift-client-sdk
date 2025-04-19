import Foundation
import Logging

/// HTTP client for making network requests to the CustomFit API
public class HttpClient {
    /// The configuration for the client
    private var config: CFConfig
    
    /// The URL session for making requests
    private var session: URLSession
    
    /// Logger
    private let logger = Logger(label: "customfit.HttpClient")
    
    /// Initialize a new HTTP client
    /// - Parameter config: The configuration for the client
    public init(config: CFConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(config.networkConnectionTimeoutMs) / 1000.0
        configuration.timeoutIntervalForResource = TimeInterval(config.networkReadTimeoutMs) / 1000.0
        
        self.session = URLSession(configuration: configuration)
    }
    
    /// Update the connection timeout
    /// - Parameter timeoutMs: The timeout in milliseconds
    public func updateConnectionTimeout(_ timeoutMs: Int) {
        let configuration = session.configuration
        configuration.timeoutIntervalForRequest = TimeInterval(timeoutMs) / 1000.0
        session = URLSession(configuration: configuration)
    }
    
    /// Update the read timeout
    /// - Parameter timeoutMs: The timeout in milliseconds
    public func updateReadTimeout(_ timeoutMs: Int) {
        let configuration = session.configuration
        configuration.timeoutIntervalForResource = TimeInterval(timeoutMs) / 1000.0
        session = URLSession(configuration: configuration)
    }
    
    /// Make a GET request
    /// - Parameters:
    ///   - url: The URL to request
    ///   - headers: Headers to include in the request
    ///   - completion: A callback to invoke with the response
    public func get(url: URL, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("HTTP GET request failed: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid HTTP response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "customfit", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data in response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    /// Make a POST request
    /// - Parameters:
    ///   - url: The URL to request
    ///   - body: The body to include in the request
    ///   - headers: Headers to include in the request
    ///   - completion: A callback to invoke with the response
    public func post(url: URL, body: Data, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add content type header if not provided
        if headers?["Content-Type"] == nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("HTTP POST request failed: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid HTTP response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "customfit", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data in response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    /// Make a PUT request
    /// - Parameters:
    ///   - url: The URL to request
    ///   - body: The body to include in the request
    ///   - headers: Headers to include in the request
    ///   - completion: A callback to invoke with the response
    public func put(url: URL, body: Data, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = body
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add content type header if not provided
        if headers?["Content-Type"] == nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("HTTP PUT request failed: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid HTTP response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "customfit", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data in response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    /// Make a DELETE request
    /// - Parameters:
    ///   - url: The URL to request
    ///   - headers: Headers to include in the request
    ///   - completion: A callback to invoke with the response
    public func delete(url: URL, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("HTTP DELETE request failed: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid HTTP response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "customfit", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data in response")
                completion(.failure(NSError(domain: "customfit", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
} 