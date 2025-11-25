import Foundation

@available(iOS, introduced: 6.0, deprecated: 7.0.1)
public class URLSessionCompat: NSObject {
    public let configuration: URLSessionConfigurationCompat
    public var delegate: URLSessionDelegateCompat?
    public let delegateQueue: OperationQueue
    
    public static let shared = URLSessionCompat(configuration: .default, delegateQueue: OperationQueue())
    
    // Designated initializer
    public init(configuration: URLSessionConfigurationCompat, delegate: URLSessionDelegateCompat? = nil, delegateQueue: OperationQueue = .main) {
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    // Convenience initialisers
    public convenience init(configuration: URLSessionConfigurationCompat) {
        self.init(configuration: configuration, delegate: nil, delegateQueue: .main)
    }
    
    public convenience override init() {
        self.init(configuration: .default, delegateQueue: .main)
    }
    
    // Prepare request by merging configuration headers
    internal func prepareRequest(_ request: URLRequest) -> URLRequest {
        var modified = request
        
        if let extra = configuration.httpAdditionalHeaders {
            var headers = modified.allHTTPHeaderFields ?? [:]
            for (key, value) in extra {
                headers[key] = value
            }
            modified.allHTTPHeaderFields = headers
        }
        
        return modified
    }
    
    // Tasks
    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskCompat {
        let prepared = prepareRequest(request)
        return URLSessionDataTaskCompat(session: self, request: prepared, completionHandler: completionHandler)
    }
    
    public func uploadTask(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionUploadTaskCompat {
        let prepared = prepareRequest(request)
        return URLSessionUploadTaskCompat(session: self, request: prepared, bodyData: bodyData, completionHandler: completionHandler)
    }
    
    public func downloadTask(
        with request: URLRequest,
        completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void
    ) -> URLSessionDownloadTaskCompat {
        let prepared = prepareRequest(request)
        return URLSessionDownloadTaskCompat(session: self, request: prepared, completionHandler: completionHandler)
    }
    
    public func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
        let prepared = prepareRequest(request)
        return URLSessionWebSocketTask(session: self, url: prepared.url!)
    }
}
