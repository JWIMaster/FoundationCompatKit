import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionDataTask {
    private let request: URLRequest
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?

    public init(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.request = request
        self.completionHandler = completionHandler
    }

    public func resume() {
        let conn = NSURLConnection(request: request, delegate: nil, startImmediately: false)
        connection = conn
        conn?.start()

        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) { response, data, error in
            self.completionHandler(data, response, error)
        }
    }

    public func cancel() {
        connection?.cancel()
    }
}
