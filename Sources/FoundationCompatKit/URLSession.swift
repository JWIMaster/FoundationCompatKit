import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSession {
    public let configuration: URLSessionConfiguration
    public static let shared = URLSession(configuration: .default)

    public init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }

    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return URLSessionDataTask(request: request, completionHandler: completionHandler)
    }

    public func uploadTask(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionUploadTask {
        return URLSessionUploadTask(request: request, bodyData: bodyData, completionHandler: completionHandler)
    }

    public func downloadTask(
        with request: URLRequest,
        completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void
    ) -> URLSessionDownloadTask {
        return URLSessionDownloadTask(request: request, completionHandler: completionHandler)
    }

    public func webSocketTask(with request: URLRequest) -> URLSessionWebSocketTask {
        return URLSessionWebSocketTask(url: request.url!)
    }
}
