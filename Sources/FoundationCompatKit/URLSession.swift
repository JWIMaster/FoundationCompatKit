import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionCompat: NSObject {
    public let configuration: URLSessionConfigurationCompat
    public var delegate: URLSessionDelegateCompat?
    public let delegateQueue: OperationQueue
    public static let shared = URLSessionCompat(configuration: .default, delegateQueue: OperationQueue())
    
    // MARK: - Designated initializer
    public init(configuration: URLSessionConfigurationCompat, delegate: URLSessionDelegateCompat? = nil, delegateQueue: OperationQueue = .main) {
        self.configuration = configuration
        self.delegate = delegate
        self.delegateQueue = delegateQueue
    }
    
    // Convenience initializers
    public convenience init(configuration: URLSessionConfigurationCompat) {
        self.init(configuration: configuration, delegate: nil, delegateQueue: .main)
    }
    
    public convenience override init() {
        self.init(configuration: .default, delegateQueue: .main)
    }
    
    // MARK: - Tasks
    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskCompat {
        return URLSessionDataTaskCompat(session: self, request: request, completionHandler: completionHandler)
    }
    
    public func uploadTask(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionUploadTaskCompat {
        return URLSessionUploadTaskCompat(session: self, request: request, bodyData: bodyData, completionHandler: completionHandler)
    }
    
    public func downloadTask(
        with request: URLRequest,
        completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void
    ) -> URLSessionDownloadTaskCompat {
        return URLSessionDownloadTaskCompat(session: self, request: request, completionHandler: completionHandler)
    }
    
    public func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
        return URLSessionWebSocketTask(session: self, url: request.url!)
    }
}
