import Foundation

extension Calendar {
    
    /// Shim for `isDateInToday(_:)` that works on iOS 6+
    @available(iOS, introduced: 6.0, obsoleted: 8.0)
    func isDateInToday(_ date: Date) -> Bool {
        let components = self.dateComponents([.year, .month, .day], from: date)
        let todayComponents = self.dateComponents([.year, .month, .day], from: Date())
        return components.year == todayComponents.year &&
        components.month == todayComponents.month &&
        components.day == todayComponents.day
    }
    
    // Optional: add similar shims for yesterday/tomorrow
    @available(iOS, introduced: 6.0, obsoleted: 8.0)
    func isDateInYesterday(_ date: Date) -> Bool {
        let components = self.dateComponents([.year, .month, .day], from: date)
        let yesterdayComponents = self.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(-86400))
        return components.year == yesterdayComponents.year &&
        components.month == yesterdayComponents.month &&
        components.day == yesterdayComponents.day
    }
    
    @available(iOS, introduced: 6.0, obsoleted: 8.0)
    func isDateInTomorrow(_ date: Date) -> Bool {
        let components = self.dateComponents([.year, .month, .day], from: date)
        let tomorrowComponents = self.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))
        return components.year == tomorrowComponents.year &&
        components.month == tomorrowComponents.month &&
        components.day == tomorrowComponents.day
    }
}
