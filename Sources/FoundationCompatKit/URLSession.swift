import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionCompat: NSObject {
    public let configuration: URLSessionConfiguration
    public var delegate: URLSessionDelegateCompat?
    public static let shared = URLSessionCompat(configuration: .default)
    
    public init(configuration: URLSessionConfiguration, delegate: URLSessionDelegateCompat? = nil) {
        self.configuration = configuration
        self.delegate = delegate
    }
    
    public init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }
    
    public convenience override init() {
        self.init(configuration: .default)
    }
    
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
