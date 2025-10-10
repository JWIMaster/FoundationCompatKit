import Foundation

public class URLSessionDownloadTaskCompat: URLSessionTaskCompat, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    private let completionHandler: (URL?, URLResponse?, Error?) -> Void
    private var connection: NSURLConnection?
    private var tempFile: URL?
    private var fileHandle: FileHandle?

    public init(session: URLSessionCompat, request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
        super.init(session: session, request: request)
    }

    public override func startTask() {
        guard state == .running else { return }

        let tempDir = NSTemporaryDirectory()
        let fileName = UUID().uuidString
        tempFile = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: tempFile!.path, contents: nil, attributes: nil)
        fileHandle = try? FileHandle(forWritingTo: tempFile!)

        connection = NSURLConnection(request: originalRequest, delegate: self, startImmediately: true)
    }

    public override func cancel() {
        super.cancel()
        connection?.cancel()
        if let tempFile = tempFile {
            try? FileManager.default.removeItem(at: tempFile)
        }
    }

    // MARK: - NSURLConnectionDataDelegate

    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        // Delegate can handle response if needed
    }

    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)

        if let delegate = session.delegate as? URLSessionDownloadDelegateCompat {
            delegate.urlSession(session, downloadTask: self,
                                didWriteData: Int64(data.count),
                                totalBytesWritten: Int64(fileHandle?.offsetInFile ?? 0),
                                totalBytesExpectedToWrite: -1) // unknown length
        }
    }

    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        fileHandle?.closeFile()
        let response: URLResponse? = connection.currentRequest.url.flatMap {
            URLResponse(url: $0, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
        }
        completionHandler(tempFile, response, nil)

        if let delegate = session.delegate as? URLSessionDownloadDelegateCompat, let tempFile = tempFile {
            delegate.urlSession(session, downloadTask: self, didFinishDownloadingTo: tempFile)
        }

        finishTask()
    }

    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        fileHandle?.closeFile()
        let response: URLResponse? = connection.currentRequest.url.flatMap {
            URLResponse(url: $0, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
        }
        completionHandler(nil, response, error)
        finishTask(with: error)
    }
}
