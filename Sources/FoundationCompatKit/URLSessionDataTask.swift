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

        // Make a mutable copy of the request
        let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        mutableRequest.httpMethod = originalRequest.httpMethod!
        mutableRequest.httpBody = originalRequest.httpBody
        if let headers = originalRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Run the connection on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // NSURLConnection schedules on the current run loop
            let runLoop = RunLoop.current
            self.connection = NSURLConnection(request: mutableRequest as URLRequest, delegate: self, startImmediately: false)
            self.connection?.schedule(in: runLoop, forMode: .default)
            self.connection?.start()

            // Keep the run loop alive so NSURLConnection callbacks are delivered
            while self.state == .running && runLoop.run(mode: .default, before: Date.distantFuture) {}
        }
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
