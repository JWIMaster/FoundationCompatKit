import Foundation

public class URLSessionUploadTaskCompat: NSObject, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    public let session: URLSessionCompat
    private let request: URLRequest
    private let bodyData: Data?
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var receivedData = Data()

    // Use the session parameter to match other tasks
    public init(session: URLSessionCompat, request: URLRequest, bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.request = request
        self.bodyData = bodyData
        self.completionHandler = completionHandler
        super.init()
    }

    public func resume() {
        var req = request
        req.httpBody = bodyData
        connection = NSURLConnection(request: req, delegate: self, startImmediately: true)
    }

    public func cancel() {
        connection?.cancel()
    }

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        receivedData.removeAll()
    }

    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        receivedData.append(data)
    }

    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        var response: URLResponse? = nil
        if let url = connection.currentRequest.url {
            response = URLResponse(url: url, mimeType: nil, expectedContentLength: receivedData.count, textEncodingName: nil)
        }
        completionHandler(receivedData, response, nil)
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        var response: URLResponse? = nil
        if let url = connection.currentRequest.url {
            response = URLResponse(url: url, mimeType: nil, expectedContentLength: receivedData.count, textEncodingName: nil)
        }
        completionHandler(nil, response, error)
    }


}
