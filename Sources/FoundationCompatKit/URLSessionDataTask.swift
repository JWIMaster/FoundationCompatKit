import Foundation

public class URLSessionDataTaskCompat: URLSessionTaskCompat, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var receivedData = Data()
    private var urlResponse: URLResponse?  // store response here

    public init(session: URLSessionCompat, request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        super.init(session: session, request: request)
    }

    public override func startTask() {
        guard state == .running else { return }

        let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        mutableRequest.httpMethod = originalRequest.httpMethod!
        if let body = originalRequest.httpBody {
            mutableRequest.httpBody = body
        }
        if let headers = originalRequest.allHTTPHeaderFields {
            for (key, value) in headers {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        connection = NSURLConnection(request: mutableRequest as URLRequest, delegate: self, startImmediately: true)
    }

    public override func cancel() {
        super.cancel()
        connection?.cancel()
    }

    // MARK: - NSURLConnectionDelegate

    public func connection(_ connection: NSURLConnection, willSendRequestFor challenge: URLAuthenticationChallenge) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: trust)
            challenge.sender?.use(credential, for: challenge)
            challenge.sender?.continueWithoutCredential(for: challenge)
        } else {
            challenge.sender?.performDefaultHandling?(for: challenge)
        }
    }

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.urlResponse = response // save response
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
        completionHandler(receivedData, urlResponse, nil)
        finishTask()
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        completionHandler(nil, urlResponse, error)
        finishTask(with: error)
    }
}
