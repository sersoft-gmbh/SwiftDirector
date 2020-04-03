public struct DistinguishedName: RawRepresentable, Hashable, Comparable, Codable, ExpressibleByStringLiteral, CustomStringConvertible, CustomDebugStringConvertible, LDAPValue {
    public typealias RawValue = String

    public let rawValue: RawValue

    public var description: String { rawValue }
    public var debugDescription: String { rawValue }

    public var ldapRaw: some LDAPRaw { rawValue.ldapRaw }

    public init(rawValue: RawValue) { self.rawValue = rawValue }

    @inlinable
    public init(stringLiteral value: RawValue.StringLiteralType) {
        self.init(rawValue: .init(stringLiteral: value))
    }

    @inlinable
    public init<Raw>(fromLDAPRaw ldapRaw: Raw) where Raw : LDAPRaw {
        self.init(rawValue: .init(fromLDAPRaw: ldapRaw))
    }

    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
