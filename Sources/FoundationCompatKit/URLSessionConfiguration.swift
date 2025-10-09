import Foundation

@available(iOS, introduced: 6.0, obsoleted: 7.0.1)
public class URLSessionConfiguration {
    public var timeoutIntervalForRequest: TimeInterval = 60
    public var timeoutIntervalForResource: TimeInterval = 7*24*60*60
    public static let `default` = URLSessionConfiguration()
    public static let ephemeral = URLSessionConfiguration()
    public static let background = URLSessionConfiguration()

    public init() {}
}
