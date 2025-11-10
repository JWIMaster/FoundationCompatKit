import Foundation

public class URLSessionDataTaskCompat: URLSessionTaskCompat, NSURLConnectionDataDelegate, NSURLConnectionDelegate {

    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var receivedData = Data()
    private var response: URLResponse?
    private var isFinished = false

    public init(session: URLSessionCompat, request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        super.init(session: session, request: request)
    }

    public override func startTask() {
        guard state == .running else { return }

        let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest

        // Set HTTP method
        if let method = originalRequest.httpMethod {
            mutableRequest.httpMethod = method
        }

        // Copy headers
        if let headers = originalRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Copy body for POST/PUT
        if let body = originalRequest.httpBody {
            mutableRequest.httpBody = body
            mutableRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }

        // Start connection
        connection = NSURLConnection(request: mutableRequest as URLRequest, delegate: self, startImmediately: true)
    }

    public override func cancel() {
        super.cancel()
        connection?.cancel()
        connection = nil
        safeComplete(data: receivedData, response: response, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
    }

    // MARK: - NSURLConnection Delegates

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.response = response
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
        // Ensure we have a valid HTTPURLResponse
        let httpResponse: HTTPURLResponse
        if let resp = response as? HTTPURLResponse {
            httpResponse = resp
        } else if let url = connection.currentRequest.url {
            let headers = connection.currentRequest.allHTTPHeaderFields ?? [:]
            httpResponse = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            ) ?? HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        } else {
            safeComplete(data: receivedData, response: response, error: nil)
            return
        }

        safeComplete(data: receivedData, response: httpResponse, error: nil)
        connection.cancel()
        self.connection = nil
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        safeComplete(data: receivedData, response: response, error: error)
        connection.cancel()
        self.connection = nil
    }

    // MARK: - Safe Completion

    private func safeComplete(data: Data?, response: URLResponse?, error: Error?) {
        guard !isFinished else { return }
        isFinished = true
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler(data, response, error)
            self?.finishTask(with: error)
        }
    }
}
