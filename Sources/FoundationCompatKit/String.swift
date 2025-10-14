import Foundation

public extension String {
    /// Backport of addingPercentEncoding(withAllowedCharacters:) for iOS 6+
    func urlPathPercentEncoded() -> String {
        if #available(iOS 7, *) {
            // Modern API available
            return self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
        } else {
            // iOS 6 fallback
            let allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/"
            let allowedSet = NSMutableCharacterSet(charactersIn: allowed)
            
            // Use legacy NSStringEncoding
            let encoding: String.Encoding = String.Encoding.utf8
            
            return (self as NSString).addingPercentEscapes(using: encoding.rawValue) ?? self
        }
    }
}
