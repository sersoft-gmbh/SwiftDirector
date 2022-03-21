/// Represents a raw LDAP value.
public protocol LDAPRaw: RandomAccessCollection where Element == String {}

extension Array: LDAPRaw where Element == String {}
extension ContiguousArray: LDAPRaw where Element == String {}
extension CollectionOfOne: LDAPRaw where Element == String {}
extension EmptyCollection: LDAPRaw where Element == String {}
extension AnyRandomAccessCollection: LDAPRaw where Element == String {}

/// Represents a type that can be converted from and to an LDAP raw type.
public protocol LDAPValue: Equatable {
    /// The raw LDAP value this type converts *to*.
    associatedtype LDAPRawType: LDAPRaw
    /// The raw LDAP value of this type.
    var ldapRaw: LDAPRawType { get }

    /// Initializes this type from a raw LDAP value.
    /// - Parameter ldapRaw: The raw LDAP value.
    init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw)
}

extension String: LDAPValue {
    public var ldapRaw: some LDAPRaw { CollectionOfOne(self) }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = ldapRaw[ldapRaw.startIndex]
    }
}

extension Bool: LDAPValue {
    public var ldapRaw: some LDAPRaw { (self ? "TRUE" : "FALSE").ldapRaw }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = String(fromLDAPRaw: ldapRaw).uppercased() == "TRUE"
    }
}

extension FixedWidthInteger where Self: LDAPValue {
    public var ldapRaw: some LDAPRaw { String(self).ldapRaw }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self.init(String(fromLDAPRaw: ldapRaw))!
    }
}

extension Int: LDAPValue {}
extension Int8: LDAPValue {}
extension Int16: LDAPValue {}
extension Int32: LDAPValue {}
extension Int64: LDAPValue {}

extension UInt: LDAPValue {}
extension UInt8: LDAPValue {}
extension UInt16: LDAPValue {}
extension UInt32: LDAPValue {}
extension UInt64: LDAPValue {}

extension LosslessStringConvertible where Self: BinaryFloatingPoint, Self: LDAPValue {
    public var ldapRaw: some LDAPRaw { String(self).ldapRaw }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self.init(String(fromLDAPRaw: ldapRaw))!
    }
}

extension Double: LDAPValue {}
extension Float: LDAPValue {}

extension Optional: LDAPValue where Wrapped: LDAPValue {
    public var ldapRaw: some LDAPRaw {
        map { AnyRandomAccessCollection($0.ldapRaw) } ?? AnyRandomAccessCollection(EmptyCollection<String>())
    }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = ldapRaw.isEmpty ? nil : Wrapped(fromLDAPRaw: ldapRaw)
    }
}

extension Array: LDAPValue where Element: LDAPValue {
    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = ldapRaw.map { Element(fromLDAPRaw: CollectionOfOne($0)) }
    }
}

extension ContiguousArray: LDAPValue where Element: LDAPValue {
    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self.init()
        reserveCapacity(ldapRaw.count)
        for elem in ldapRaw {
            append(.init(fromLDAPRaw: CollectionOfOne(elem)))
        }
    }
}

extension Set: LDAPValue where Element: LDAPValue {
    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self.init(minimumCapacity: ldapRaw.count)
        for elem in ldapRaw {
            insert(.init(fromLDAPRaw: CollectionOfOne(elem)))
        }
    }
}
