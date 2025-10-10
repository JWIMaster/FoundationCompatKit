import Foundation

public protocol URLSessionDelegateCompat {
    func urlSession(_ session: URLSessionCompat, didBecomeInvalidWithError error: Error?)
    func urlSession(_ session: URLSessionCompat, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSessionCompat)
}

public extension URLSessionDelegateCompat {
    func urlSession(_ session: URLSessionCompat, didBecomeInvalidWithError error: Error?) {}
    func urlSession(_ session: URLSessionCompat, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSessionCompat) {}
}

public protocol URLSessionTaskDelegateCompat: URLSessionDelegateCompat {
    func urlSession(_ session: URLSessionCompat, task: URLSessionTaskCompat, didCompleteWithError error: Error?)
    func urlSession(_ session: URLSessionCompat, task: URLSessionTaskCompat, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

public extension URLSessionTaskDelegateCompat {
    func urlSession(_ session: URLSessionCompat, task: URLSessionTaskCompat, didCompleteWithError error: Error?) {}
    func urlSession(_ session: URLSessionCompat, task: URLSessionTaskCompat, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}

public protocol URLSessionDataDelegateCompat: URLSessionTaskDelegateCompat {
    func urlSession(_ session: URLSessionCompat, dataTask: URLSessionDataTaskCompat, didReceive data: Data)
    func urlSession(_ session: URLSessionCompat, dataTask: URLSessionDataTaskCompat, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
}

public extension URLSessionDataDelegateCompat {
    func urlSession(_ session: URLSessionCompat, dataTask: URLSessionDataTaskCompat, didReceive data: Data) {}
    func urlSession(_ session: URLSessionCompat, dataTask: URLSessionDataTaskCompat, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}

public protocol URLSessionDownloadDelegateCompat: URLSessionTaskDelegateCompat {
    func urlSession(_ session: URLSessionCompat, downloadTask: URLSessionDownloadTaskCompat, didFinishDownloadingTo location: URL)
    func urlSession(_ session: URLSessionCompat, downloadTask: URLSessionDownloadTaskCompat, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
}

public extension URLSessionDownloadDelegateCompat {
    func urlSession(_ session: URLSessionCompat, downloadTask: URLSessionDownloadTaskCompat, didFinishDownloadingTo location: URL) {}
    func urlSession(_ session: URLSessionCompat, downloadTask: URLSessionDownloadTaskCompat, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {}
}

public protocol URLSessionUploadDelegateCompat: URLSessionTaskDelegateCompat {}
public extension URLSessionUploadDelegateCompat {}
