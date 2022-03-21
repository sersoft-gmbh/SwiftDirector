/// Represents a key for an attribute.
public struct AttributeKey: RawRepresentable, Hashable, Comparable, Codable, ExpressibleByStringLiteral, CustomStringConvertible, CustomDebugStringConvertible {
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

/// Represents an (typed) attribute containing its key.
public struct Attribute<Value: LDAPValue>: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    /// The key for this attribute.
    public let key: AttributeKey

    public var description: String { "\(key): \(Value.self)" }
    public var debugDescription: String { description }

    /// Creates a new attribute with the given key.
    /// - Parameter key: The key to use for this attribute.
    public init(key: AttributeKey) { self.key = key }
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension AttributeKey: Sendable {}
extension Attribute: Sendable {} // independent of `Value`, since `Value` is only in the type signature.
#endif
