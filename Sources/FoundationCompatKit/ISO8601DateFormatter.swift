import Foundation

// Backport ISO8601DateFormatter for iOS < 10
class ISO8601DateFormatterCompat {
    struct Options: OptionSet {
        let rawValue: Int
        static let withInternetDateTime = Options(rawValue: 1 << 0)
        static let withFractionalSeconds = Options(rawValue: 1 << 1)
    }

    var formatOptions: Options = [.withInternetDateTime]

    private let baseFormatter: DateFormatter
    private let fractionalFormatter: DateFormatter

    init() {
        baseFormatter = DateFormatter()
        baseFormatter.locale = Locale(identifier: "en_US_POSIX")
        baseFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        baseFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

        fractionalFormatter = DateFormatter()
        fractionalFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fractionalFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    }

    func date(from string: String) -> Date? {
        if formatOptions.contains(.withFractionalSeconds),
           let date = fractionalFormatter.date(from: string) {
            return date
        }
        return baseFormatter.date(from: string)
    }

    func string(from date: Date) -> String {
        if formatOptions.contains(.withFractionalSeconds) {
            return fractionalFormatter.string(from: date)
        }
        return baseFormatter.string(from: date)
    }
}
