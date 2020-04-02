public struct AttributeKey: RawRepresentable, Hashable, CustomStringConvertible, ExpressibleByStringLiteral {
    public typealias RawValue = String

    public let rawValue: RawValue

    public var description: String { rawValue }

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    @inlinable
    public init(stringLiteral value: RawValue.StringLiteralType) {
        self.init(rawValue: .init(stringLiteral: value))
    }
}

public struct Attribute<Value: LDAPValue>: Hashable {
    public let key: AttributeKey
    public init(key: AttributeKey) { self.key = key }
}
