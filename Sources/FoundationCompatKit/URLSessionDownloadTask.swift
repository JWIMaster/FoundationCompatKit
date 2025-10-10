import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionDownloadTaskCompat {
    private let request: URLRequest
    private let completionHandler: (URL?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?

    public init(request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        self.request = request
        self.completionHandler = completionHandler
    }

    public func resume() {
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) { response, data, error in
            var tmpURL: URL? = nil
            if let data = data {
                let tmpDir = NSTemporaryDirectory()
                tmpURL = URL(fileURLWithPath: tmpDir).appendingPathComponent(UUID().uuidString)
                try? data.write(to: tmpURL!)
            }
            self.completionHandler(tmpURL, response, error)
        }
    }

    public func cancel() {
        connection?.cancel()
    }
}
