import Foundation
import Network
import Logging

/// Connection manager for monitoring network connectivity
public class ConnectionManager {
    /// The current connection status
    private var currentStatus: ConnectionStatus = .unknown
    
    /// Information about the current connection
    private var connectionInfo = ConnectionInformation()
    
    /// The network path monitor
    private let pathMonitor = NWPathMonitor()
    
    /// The dispatch queue to run the path monitor on
    private let monitorQueue = DispatchQueue(label: "customfit.network.monitor")
    
    /// Listeners for connection status changes
    private var listeners: [(ConnectionStatus, ConnectionInformation) -> Void] = []
    
    /// Whether the manager is in offline mode
    private var offlineMode: Bool = false
    
    /// The callback to invoke when connected
    private let onConnected: () -> Void
    
    /// Logger
    private let logger = Logger(label: "customfit.ConnectionManager")
    
    /// Initialize a new connection manager
    /// - Parameter onConnected: A callback to invoke when connected
    public init(onConnected: @escaping () -> Void) {
        self.onConnected = onConnected
        
        // Set up the path monitor
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if self.offlineMode {
                // If we're in offline mode, always report as disconnected
                self.updateStatus(.disconnected)
                return
            }
            
            switch path.status {
            case .satisfied:
                self.updateStatus(.connected)
                
                // Invoke the onConnected callback when we connect
                self.onConnected()
                
            case .unsatisfied:
                self.updateStatus(.disconnected)
                
            case .requiresConnection:
                self.updateStatus(.disconnected)
                
            @unknown default:
                self.updateStatus(.unknown)
            }
        }
        
        // Start monitoring
        pathMonitor.start(queue: monitorQueue)
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    /// Set the offline mode
    /// - Parameter offlineMode: Whether the manager should be in offline mode
    public func setOfflineMode(_ offlineMode: Bool) {
        self.offlineMode = offlineMode
        
        // If we're switching to offline mode, update the status
        if offlineMode {
            updateStatus(.disconnected)
        } else {
            // If we're switching out of offline mode, get the current path status
            let path = pathMonitor.currentPath
            switch path.status {
            case .satisfied:
                updateStatus(.connected)
            case .unsatisfied, .requiresConnection:
                updateStatus(.disconnected)
            @unknown default:
                updateStatus(.unknown)
            }
        }
    }
    
    /// Update the connection status
    /// - Parameter newStatus: The new status
    private func updateStatus(_ newStatus: ConnectionStatus) {
        let oldStatus = currentStatus
        currentStatus = newStatus
        
        if newStatus == .connected {
            // Update the last successful connection time
            connectionInfo = ConnectionInformation(
                lastSuccessfulConnectionTimeMs: UInt64(Date().timeIntervalSince1970 * 1000),
                error: nil
            )
        }
        
        // Notify listeners if the status has changed
        if oldStatus != newStatus {
            logger.debug("Connection status changed: \(oldStatus) -> \(newStatus)")
            
            // Notify listeners on the main queue
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                for listener in self.listeners {
                    listener(self.currentStatus, self.connectionInfo)
                }
            }
        }
    }
    
    /// Add a listener for connection status changes
    /// - Parameter listener: The listener to add
    public func addConnectionStatusListener(_ listener: @escaping (ConnectionStatus, ConnectionInformation) -> Void) {
        listeners.append(listener)
        
        // Immediately notify the listener of the current status
        listener(currentStatus, connectionInfo)
    }
    
    /// Get the current connection status
    /// - Returns: The current status
    public func getCurrentStatus() -> ConnectionStatus {
        return currentStatus
    }
    
    /// Get the current connection information
    /// - Returns: The current information
    public func getConnectionInfo() -> ConnectionInformation {
        return connectionInfo
    }
} 