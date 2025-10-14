import Foundation

public class URLSessionDataTaskCompat: URLSessionTaskCompat, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var receivedData = Data()

    public init(session: URLSessionCompat, request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        super.init(session: session, request: request)
    }

    public override func startTask() {
        guard state == .running else { return }

        // Make a mutable copy of the original request
        let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest

        // Set the HTTP method explicitly
        mutableRequest.httpMethod = originalRequest.httpMethod!

        // Set the body explicitly for POST/PUT
        if let body = originalRequest.httpBody {
            mutableRequest.httpBody = body
        }

        // Copy headers
        if let headers = originalRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Use NSURLConnection to start the request
        connection = NSURLConnection(request: mutableRequest as URLRequest, delegate: self, startImmediately: true)
    }



    public override func cancel() {
        super.cancel()
        connection?.cancel()
    }

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        if let delegate = session.delegate as? URLSessionDataDelegateCompat {
            delegate.urlSession(session, dataTask: self, didReceive: response) { _ in }
        }
    }

    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        receivedData.append(data)
        if let delegate = session.delegate as? URLSessionDataDelegateCompat {
            delegate.urlSession(session, dataTask: self, didReceive: data)
        }
    }

    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        completionHandler(receivedData, connection.currentRequest.url.flatMap { URLResponse(url: $0, mimeType: nil, expectedContentLength: receivedData.count, textEncodingName: nil) }, nil)
        finishTask()
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        completionHandler(nil, connection.currentRequest.url.flatMap { URLResponse(url: $0, mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }, error)
        finishTask(with: error)
    }
}
