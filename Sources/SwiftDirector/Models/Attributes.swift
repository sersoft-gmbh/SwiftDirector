public struct AttributeKey: RawRepresentable, Hashable, Comparable, ExpressibleByStringLiteral, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias RawValue = String

    public let rawValue: RawValue

    public var description: String { rawValue }
    public var debugDescription: String { rawValue }

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    @inlinable
    public init(stringLiteral value: RawValue.StringLiteralType) {
        self.init(rawValue: .init(stringLiteral: value))
    }

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct Attribute<Value: LDAPValue>: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let key: AttributeKey

    public var description: String { "\(key): \(Value.self)" }
    public var debugDescription: String { description }

    public init(key: AttributeKey) { self.key = key }
}
