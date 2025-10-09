import Foundation
import SocketRocket

public class URLSessionWebSocketTask: NSObject {
    public enum Message {
        case data(Data)
        case string(String)
    }

    public enum CloseCode: Int {
        case normalClosure = 1000
        case goingAway = 1001
        case protocolError = 1002
        case unsupportedData = 1003
        case noStatusReceived = 1005
        case abnormalClosure = 1006
        case invalidFramePayloadData = 1007
        case policyViolation = 1008
        case messageTooBig = 1009
        case mandatoryExtension = 1010
        case internalServerError = 1011
        case tlsHandshake = 1015
        case unknown = -1
    }

    public enum State: Int {
        case running, suspended, canceling, completed
    }

    public private(set) var state: State = .suspended
    public var maximumMessageSize: Int64 = Int64.max

    private var socket: SRWebSocket?
    private let url: URL
    private var pendingReceive: ((Result<Message, Error>) -> Void)?
    private var pongHandler: (() -> Void)?
    private var isOpen = false

    public init(url: URL) {
        self.url = url
    }

    public func resume() {
        let request = URLRequest(url: url)
        socket = SRWebSocket(urlRequest: request)
        socket?.delegate = self
        socket?.open()
        state = .running
    }

    @preconcurrency
    public func send(
        _ message: URLSessionWebSocketTask.Message,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard let socket = socket, isOpen else {
            completionHandler(NSError(domain: "WebSocketCompat", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebSocket not open"]))
            return
        }

        switch message {
        case .string(let text):
            socket.send(text)
        case .data(let data):
            socket.send(data)
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
        let reasonString: String?
        if let reason = reason {
            reasonString = String(data: reason, encoding: .utf8)
        } else {
            reasonString = nil
        }

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
        if let text = message as? String {
            handler(.success(.string(text)))
        } else if let data = message as? Data {
            handler(.success(.data(data)))
        } else {
            handler(.failure(NSError(domain: "WebSocketCompat", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unsupported message type"])))
        }
        pendingReceive = nil
    }

    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isOpen = false
        state = .completed
        let error = NSError(domain: "WebSocketCompat", code: code, userInfo: [NSLocalizedDescriptionKey: reason ?? "Closed"])
        pendingReceive?(.failure(error))
        pendingReceive = nil
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        pongHandler?()
        pongHandler = nil
    }
}
