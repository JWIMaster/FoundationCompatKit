import Foundation

@available(iOS, introduced: 6.0, deprecated: 7.0.1)
public class URLSessionConfigurationCompat {
    public var timeoutIntervalForRequest: TimeInterval = 60
    public var timeoutIntervalForResource: TimeInterval = 7*24*60*60
    public static let `default` = URLSessionConfigurationCompat()
    public static let ephemeral = URLSessionConfigurationCompat()
    public static let background = URLSessionConfigurationCompat()

    public init() {}
}
