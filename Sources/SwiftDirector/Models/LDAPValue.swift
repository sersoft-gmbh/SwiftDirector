public protocol LDAPRaw: RandomAccessCollection where Element == String {}
extension Array: LDAPRaw where Element == String {}
extension CollectionOfOne: LDAPRaw where Element == String {}
extension EmptyCollection: LDAPRaw where Element == String {}
extension AnyRandomAccessCollection: LDAPRaw where Element == String {}

public protocol LDAPValue: Equatable {
    associatedtype LDAPRawType: LDAPRaw
    var ldapRaw: LDAPRawType { get }

    init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw)
}

extension String: LDAPValue {
    public var ldapRaw: some LDAPRaw { CollectionOfOne(self) }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = ldapRaw[ldapRaw.startIndex]
    }
}

extension Int: LDAPValue {
    public var ldapRaw: some LDAPRaw { String(self).ldapRaw }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = Int(String(fromLDAPRaw: ldapRaw))!
    }
}

extension Bool: LDAPValue {
    public var ldapRaw: some LDAPRaw { (self ? "TRUE" : "FALSE").ldapRaw }

    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
        self = String(fromLDAPRaw: ldapRaw) == "TRUE"
    }
}

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
