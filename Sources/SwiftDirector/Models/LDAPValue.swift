/*public struct LDAPRaw: RandomAccessCollection {
    public typealias Element = String
    public typealias Index = Int
    public typealias SubSequence = AnyRandomAccessCollection
    public typealias Indices = AnyRandomAccessCollection

    @usableFromInline
    enum Storage {
        case array(Array<Element>)
        case singleValue(CollectionOfOne<Element>)
        case empty(EmptyCollection<Element>)
    }

    @usableFromInline
    let storage: Storage

    public subscript(position: Int) -> String {
        _read {
            switch storage {
            case .array(let arr): return arr[position]
            case .singleValue(let str):
                precondition(position == 0, "Index out of bounds!")
                return str
            case .empty: preconditionFailure("Index out of bounds!")
            }
        }
    }
    public var startIndex: Int {
        switch storage {
        case .array(let arr): return arr.startIndex
        case .singleValue(_): return 0
        case .empty: return 0
        }
    }

    public var endIndex: Int {
        switch storage {
        case .array(let arr): return arr.endIndex
        case .singleValue(_): return 1
        case .empty: return 0
        }
    }
}*/

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
    public var ldapRaw: some LDAPRaw { String(self).ldapRaw }

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
