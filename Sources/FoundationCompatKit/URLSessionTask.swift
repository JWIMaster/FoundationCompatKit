import Foundation

public class URLSessionTaskCompat: NSObject {
    public let session: URLSessionCompat
    public let originalRequest: URLRequest
    public private(set) var state: URLSessionTaskState = .suspended
    public var error: Error?

    public enum URLSessionTaskState {
        case running, suspended, canceling, completed
    }

    public init(session: URLSessionCompat, request: URLRequest) {
        self.session = session
        self.originalRequest = request
    }

    public func resume() {
        guard state != .running else { return }
        state = .running
        startTask()
    }

    public func suspend() {
        guard state == .running else { return }
        state = .suspended
    }

    public func cancel() {
        guard state != .completed else { return }
        state = .canceling
        finishTask(with: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
    }

    open func startTask() {}
    
    open func finishTask(with error: Error? = nil) {
        self.error = error
        state = .completed
        if let delegate = session.delegate as? URLSessionTaskDelegateCompat {
            delegate.urlSession(session, task: self, didCompleteWithError: error)
        }
    }
}
