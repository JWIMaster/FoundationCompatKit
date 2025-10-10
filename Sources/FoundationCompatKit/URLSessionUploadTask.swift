import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionUploadTaskCompat {
    private let request: URLRequest
    private let bodyData: Data?
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?

    public init(request: URLRequest, bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.request = request
        self.bodyData = bodyData
        self.completionHandler = completionHandler
    }

    public func resume() {
        var req = request
        req.httpBody = bodyData
        let conn = NSURLConnection(request: req, delegate: nil, startImmediately: false)
        connection = conn
        conn?.start()

        NSURLConnection.sendAsynchronousRequest(req, queue: OperationQueue.main) { response, data, error in
            self.completionHandler(data, response, error)
        }
    }

    public func cancel() {
        connection?.cancel()
    }
}
