import Foundation


public class ISO8601DateFormatterCompat {
    public struct Options: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        public static let withInternetDateTime = Options(rawValue: 1 << 0)
        public static let withFractionalSeconds = Options(rawValue: 1 << 1)
    }

    public var formatOptions: Options = [.withInternetDateTime]

    private let baseFormatter: DateFormatter
    private let fractionalFormatter: DateFormatter

    public init() {
        baseFormatter = DateFormatter()
        baseFormatter.locale = Locale(identifier: "en_US_POSIX")
        baseFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        baseFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

        fractionalFormatter = DateFormatter()
        fractionalFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fractionalFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    }

    public func date(from string: String) -> Date? {
        if formatOptions.contains(.withFractionalSeconds),
           let date = fractionalFormatter.date(from: string) {
            return date
        }
        return baseFormatter.date(from: string)
    }

    public func string(from date: Date) -> String {
        if formatOptions.contains(.withFractionalSeconds) {
            return fractionalFormatter.string(from: date)
        }
        return baseFormatter.string(from: date)
    }
}
