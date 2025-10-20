import Foundation
import SocketRocket

public class URLSessionWebSocketTask: NSObject {
    public let session: URLSessionCompat
    public let url: URL
    private var socket: SRWebSocket?
    public var isOpen = false
    private var pendingReceive: ((Result<Message, Error>) -> Void)?
    private var pongHandler: (() -> Void)?

    public enum Message {
        case data(Data)
        case string(String)
    }

    public enum CloseCode: Int {
        case normalClosure = 1000, goingAway = 1001, protocolError = 1002
        case unsupportedData = 1003, noStatusReceived = 1005, abnormalClosure = 1006
        case invalidFramePayloadData = 1007, policyViolation = 1008, messageTooBig = 1009
        case mandatoryExtension = 1010, internalServerError = 1011, tlsHandshake = 1015, unknown = -1
    }

    public enum State: Int { case running, suspended, canceling, completed }
    public private(set) var state: State = .suspended
    public var maximumMessageSize: Int64 = Int64.max

    public init(session: URLSessionCompat, url: URL) {
        self.session = session
        self.url = url
        super.init()
    }

    public func resume() {
        let request = URLRequest(url: url)
        socket = SRWebSocket(urlRequest: request)
        socket?.delegate = self
        socket?.open()
        state = .running
    }

    public func send(_ message: Message, completionHandler: @escaping (Error?) -> Void) {
        guard let socket = socket, isOpen else {
            completionHandler(NSError(domain: "WebSocketCompat", code: -1, userInfo: nil))
            return
        }

        switch message {
        case .string(let text): socket.send(text)
        case .data(let data): socket.send(data)
        }

        completionHandler(nil)
    }

    public func receive(completionHandler: @escaping (Result<Message, Error>) -> Void) {
        pendingReceive = completionHandler
    }

    public func sendPing(pongReceiveHandler: (() -> Void)? = nil) {
        pongHandler = pongReceiveHandler
        socket?.sendPing(nil)
    }

    public func cancel(with closeCode: CloseCode = .normalClosure, reason: Data? = nil) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) }
        socket?.close(withCode: closeCode.rawValue, reason: reasonString)
        socket = nil
        state = .completed
    }
}

extension URLSessionWebSocketTask: SRWebSocketDelegate {
    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        isOpen = true
    }

    public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        pendingReceive?(.failure(error))
        pendingReceive = nil
        isOpen = false
        state = .completed
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        guard let handler = pendingReceive else { return }
        if let text = message as? String { handler(.success(.string(text))) }
        else if let data = message as? Data { handler(.success(.data(data))) }
        else { handler(.failure(NSError(domain: "WebSocketCompat", code: -2))) }
        pendingReceive = nil
    }

    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isOpen = false
        state = .completed
        pendingReceive?(.failure(NSError(domain: "WebSocketCompat", code: code, userInfo: [NSLocalizedDescriptionKey: reason ?? "Closed"])))
        pendingReceive = nil
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        pongHandler?()
        pongHandler = nil
    }
}
