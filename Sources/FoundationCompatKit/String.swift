import Foundation

public extension String {
    /// Backport of addingPercentEncoding(withAllowedCharacters:) for iOS 6+
    func urlPathPercentEncoded() -> String {
        let allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/"
        let allowedSet = NSMutableCharacterSet(charactersIn: allowed)
        
        // Use legacy NSStringEncoding
        let encoding: String.Encoding = String.Encoding.utf8
        
        return (self as NSString).addingPercentEscapes(using: encoding.rawValue) ?? self
    }
}

public extension String {

    @_disfavoredOverload
    func addingPercentEncoding(withAllowedCharacters allowed: CharacterSetCompat) -> String {
        var result = ""
        let utf8Bytes = Array(self.utf8)

        for byte in utf8Bytes {
            let scalar = Unicode.Scalar(byte)
            if allowed.contains(scalar) {
                result.append(Character(scalar))
            } else {
                let hex = String(byte, radix: 16, uppercase: true)
                result.append("%")
                if hex.count == 1 {
                    result.append("0")
                }
                result.append(hex)
            }
        }

        return result
    }
}


import Foundation

public struct CharacterSetCompat {

    private let containsScalar: (Unicode.Scalar) -> Bool

    private init(_ contains: @escaping (Unicode.Scalar) -> Bool) {
        self.containsScalar = contains
    }

    public func contains(_ scalar: Unicode.Scalar) -> Bool {
        containsScalar(scalar)
    }

    public func contains(_ character: Character) -> Bool {
        for scalar in character.unicodeScalars {
            if !containsScalar(scalar) {
                return false
            }
        }
        return true
    }

    // MARK: Constructors

    public static func characters(in string: String) -> CharacterSetCompat {
        let scalars = Set(string.unicodeScalars)
        return CharacterSetCompat { scalars.contains($0) }
    }

    public static func inverted(_ set: CharacterSetCompat) -> CharacterSetCompat {
        return CharacterSetCompat { !set.contains($0) }
    }

    public static func union(_ a: CharacterSetCompat, _ b: CharacterSetCompat) -> CharacterSetCompat {
        return CharacterSetCompat { a.contains($0) || b.contains($0) }
    }

    public static func intersection(_ a: CharacterSetCompat, _ b: CharacterSetCompat) -> CharacterSetCompat {
        return CharacterSetCompat { a.contains($0) && b.contains($0) }
    }

    // MARK: Standard Foundation sets

    public static let alphanumerics = CharacterSetCompat {
        switch $0.properties.generalCategory {
        case .uppercaseLetter,
             .lowercaseLetter,
             .titlecaseLetter,
             .modifierLetter,
             .otherLetter,
             .decimalNumber:
            return true
        default:
            return false
        }
    }

    public static let letters = CharacterSetCompat {
        switch $0.properties.generalCategory {
        case .uppercaseLetter,
             .lowercaseLetter,
             .titlecaseLetter,
             .modifierLetter,
             .otherLetter:
            return true
        default:
            return false
        }
    }

    public static let decimalDigits = CharacterSetCompat {
        $0.properties.generalCategory == .decimalNumber
    }

    public static let whitespaces = CharacterSetCompat {
        switch $0.value {
        case 0x20, 0x09:
            return true
        default:
            return false
        }
    }

    public static let whitespacesAndNewlines = CharacterSetCompat {
        switch $0.value {
        case 0x20, 0x09, 0x0A, 0x0D:
            return true
        default:
            return false
        }
    }

    public static let newlines = CharacterSetCompat {
        switch $0.value {
        case 0x0A, 0x0D:
            return true
        default:
            return false
        }
    }

    public static let controlCharacters = CharacterSetCompat {
        $0.properties.generalCategory == .control
    }

    public static let punctuationCharacters = CharacterSetCompat {
        switch $0.properties.generalCategory {
        case .connectorPunctuation,
             .dashPunctuation,
             .openPunctuation,
             .closePunctuation,
             .initialPunctuation,
             .finalPunctuation,
             .otherPunctuation:
            return true
        default:
            return false
        }
    }

    public static let symbols = CharacterSetCompat {
        switch $0.properties.generalCategory {
        case .mathSymbol,
             .currencySymbol,
             .modifierSymbol,
             .otherSymbol:
            return true
        default:
            return false
        }
    }

    public static let urlPathAllowed = CharacterSetCompat.characters(
        in: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/._~"
    )

    public static let urlQueryAllowed = CharacterSetCompat.characters(
        in: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/?:@-._~!$&'()*+,;="
    )
}
