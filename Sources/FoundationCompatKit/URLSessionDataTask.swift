import Foundation

public class URLSessionDataTaskCompat: URLSessionTaskCompat, NSURLConnectionDataDelegate, NSURLConnectionDelegate {

    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var receivedData = Data()
    private var response: URLResponse?

    public init(session: URLSessionCompat, request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        super.init(session: session, request: request)
    }

    public override func startTask() {
        guard state == .running else { return }

        let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest

        // Explicitly set HTTP method
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
    }

    // MARK: - NSURLConnection Delegates

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        // Keep reference
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
        // Convert to proper HTTPURLResponse
        let httpResponse: HTTPURLResponse
        if let resp = response as? HTTPURLResponse {
            httpResponse = resp
        } else if let url = connection.currentRequest.url {
            httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: connection.currentRequest.allHTTPHeaderFields) ?? HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        } else {
            // Should never happen
            completionHandler(receivedData, response, nil)
            finishTask()
            return
        }

        completionHandler(receivedData, httpResponse, nil)
        finishTask()
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        completionHandler(receivedData, response, error)
        finishTask(with: error)
    }
}
