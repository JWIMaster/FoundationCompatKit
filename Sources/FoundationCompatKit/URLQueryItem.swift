import Foundation

// Backport of URLQueryItem
public struct URLQueryItemCompat {
    public var name: String
    public var value: String?
    
    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

// Backport of URLComponents for iOS 6-7
public struct URLComponentsCompat {
    public var scheme: String?
    public var host: String?
    public var port: Int?
    public var path: String = ""
    public var fragment: String?
    
    private var _queryItems: [URLQueryItemCompat]? = nil
    public var queryItems: [URLQueryItemCompat]? {
        get { _queryItems }
        set { _queryItems = newValue }
    }
    
    public init?(string: String) {
        guard let url = NSURL(string: string) else { return nil }
        self.scheme = url.scheme
        self.host = url.host
        self.port = url.port?.intValue
        self.path = url.path ?? ""
        self.fragment = url.fragment
        self._queryItems = url.queryItemsCompat()
    }
    
    public var url: URL? {
        return URL(string: self.string)
    }
    
    public var string: String {
        var components: [String] = []
        if let scheme = scheme {
            components.append("\(scheme)://")
        }
        if let host = host {
            components.append(host)
        }
        if let port = port {
            components.append(":\(port)")
        }
        components.append(path)
        
        if let queryItems = _queryItems, !queryItems.isEmpty {
            let query = queryItems.map { item -> String in
                if let value = item.value {
                    let nameEscaped = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
                    let valueEscaped = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(nameEscaped)=\(valueEscaped)"
                } else {
                    return item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
                }
            }.joined(separator: "&")
            components.append("?\(query)")
        }
        
        if let fragment = fragment {
            components.append("#\(fragment)")
        }
        
        return components.joined()
    }
}

// NSURL extension for parsing query items
private extension NSURL {
    func queryItemsCompat() -> [URLQueryItemCompat]? {
        guard let query = self.query else { return nil }
        return query.components(separatedBy: "&").map { pair in
            let elements = pair.components(separatedBy: "=")
            let name = elements[0].removingPercentEncoding ?? elements[0]
            let value = elements.count > 1 ? elements[1].removingPercentEncoding : nil
            return URLQueryItemCompat(name: name, value: value)
        }
    }
}
