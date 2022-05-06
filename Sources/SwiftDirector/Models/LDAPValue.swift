//@preconcurrency
//public protocol LDAPRaw: RandomAccessCollection, Sendable where Element == String {}

/// Represents a raw LDAP value.
/// - SeeAlso: ``LDAPValue``
public struct LDAPRaw: Hashable, _SwiftDirectorSendable {
    @usableFromInline
    enum _Storage: Hashable, _SwiftDirectorSendable, Collection {
        @usableFromInline
        typealias Element = String

        case empty
        case singleValue(String)
        case valueList(Array<String>)

        @usableFromInline
        struct Iterator: IteratorProtocol {
            @usableFromInline
            enum _Storage {
                case empty
                case singleValue(String)
                case valueList(Array<String>.Iterator)
            }

            @usableFromInline
            var _storage: _Storage

            @usableFromInline
            init(_storage: _Storage) {
                self._storage = _storage
            }

            @inlinable
            mutating func next() -> Element? {
                switch _storage {
                case .empty: return nil
                case .singleValue(let string):
                    defer { _storage = .empty }
                    return string
                case .valueList(var iterator):
                    defer { _storage = .valueList(iterator) }
                    return iterator.next()
                }
            }
        }

        @usableFromInline
        struct Index: Hashable, Comparable {
            @usableFromInline
            let _storage: Int

            @usableFromInline
            init(_storage: Int) {
                self._storage = _storage
            }

            @inlinable
            static func <(lhs: Self, rhs: Self) -> Bool {
                lhs._storage < rhs._storage
            }
        }

        @inlinable
        var startIndex: Index {
            switch self {
            case .empty, .singleValue(_): return .init(_storage: 0)
            case .valueList(let list): return .init(_storage: list.startIndex)
            }
        }

        @inlinable
        var endIndex: Index {
            switch self {
            case .empty: return .init(_storage: 0)
            case .singleValue(_): return .init(_storage: 1)
            case .valueList(let list): return .init(_storage: list.endIndex)
            }
        }

        @inlinable
        var count: Int {
            switch self {
            case .empty: return 0
            case .singleValue(_): return 1
            case .valueList(let list): return list.count
            }
        }

        @inlinable
        var isEmpty: Bool {
            switch self {
            case .empty: return true
            case .singleValue(_): return false
            case .valueList(let list): return list.isEmpty
            }
        }

        @inlinable
        subscript(position: Index) -> Element {
            switch self {
            case .empty: fatalError("Out of bounds!")
            case .singleValue(let value) where position._storage == 0: return value
            case .singleValue(_): fatalError("Out of bounds!")
            case .valueList(let list): return list[position._storage]
            }
        }

        @inlinable
        func makeIterator() -> Iterator {
            switch self {
            case .empty: return .init(_storage: .empty)
            case .singleValue(let str): return .init(_storage: .singleValue(str))
            case .valueList(let list): return .init(_storage: .valueList(list.makeIterator()))
            }
        }

        @inlinable
        func index(after i: Index) -> Index {
            switch self {
            case .empty, .singleValue(_): return .init(_storage: i._storage + 1)
            case .valueList(let list): return .init(_storage: list.index(after: i._storage))
            }
        }
    }

    @usableFromInline
    let _storage: _Storage

    init(_storage: _Storage) {
        self._storage = _storage
    }

    init(_ value: String) {
        self.init(_storage: .singleValue(value))
    }

    init<Values>(_ values: Values)
    where Values: Collection, Values.Element == String
    {
        self.init(_storage: values.isEmpty ? .empty : values.count == 1 ? .singleValue(values[values.startIndex]) : .valueList(.init(values)))
    }

    init<Values>(_ values: Values)
    where Values: Collection, Values.Element == LDAPRaw
    {
        let storage: _Storage
        if values.isEmpty {
            storage = .empty
        } else if values.count == 1 {
            storage = values[values.startIndex]._storage
        } else {
            storage = values.dropFirst().reduce(into: values[values.startIndex]._storage) {
                switch ($0, $1._storage) {
                case (_, .empty): break
                case (.empty, let other): $0 = other
                case (.singleValue(let ourValue), .singleValue(let otherValue)): $0 = .valueList([ourValue, otherValue])
                case (.valueList(let ourList), .valueList(let otherList)): $0 = .valueList(ourList + otherList)
                case (.singleValue(let ourValue), .valueList(let otherList)): $0 = .valueList(CollectionOfOne(ourValue) + otherList)
                case (.valueList(let ourList), .singleValue(let otherValue)): $0 = .valueList(ourList + CollectionOfOne(otherValue))
                }
            }
        }
        self.init(_storage: storage)
    }

    var firstValue: String? {
        switch _storage {
        case .empty: return nil
        case .singleValue(let string): return string
        case .valueList(let array): return array.first
        }
    }

    static var _empty: Self { .init(_storage: .empty) }
}

//extension Array: LDAPRaw where Element == String {}
//extension ContiguousArray: LDAPRaw where Element == String {}
//extension CollectionOfOne: LDAPRaw where Element == String {}
//extension EmptyCollection: LDAPRaw where Element == String {}
//extension AnyRandomAccessCollection: LDAPRaw where Element == String {}

#if compiler(>=5.6)
/// Represents a type that can be converted from and to an LDAP raw type.
@preconcurrency
public protocol LDAPValue: Equatable, _SwiftDirectorSendable {
    /// The raw LDAP value this type converts *to*.
//    associatedtype LDAPRawType: LDAPRaw
    /// The raw LDAP value of this type.
    var ldapRaw: LDAPRaw { get }

    /// Initializes this type from a raw LDAP value.
    /// - Parameter ldapRaw: The raw LDAP value.
    init(fromLDAPRaw ldapRaw: LDAPRaw)
}
#else
/// Represents a type that can be converted from and to an LDAP raw type.
public protocol LDAPValue: Equatable, _SwiftDirectorSendable {
    /// The raw LDAP value this type converts *to*.
//    associatedtype LDAPRawType: LDAPRaw
    /// The raw LDAP value of this type.
    var ldapRaw: LDAPRaw { get }

    /// Initializes this type from a raw LDAP value.
    /// - Parameter ldapRaw: The raw LDAP value.
    init(fromLDAPRaw ldapRaw: LDAPRaw)
}
#endif

extension String: LDAPValue {
//    public var ldapRaw: some LDAPRaw { CollectionOfOne(self) }
    public var ldapRaw: LDAPRaw { .init(self) }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self = ldapRaw[ldapRaw.startIndex]
//    }

    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self = ldapRaw.firstValue!
    }
}

extension Bool: LDAPValue {
    public var ldapRaw: LDAPRaw { (self ? "TRUE" : "FALSE").ldapRaw }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self = String(fromLDAPRaw: ldapRaw).uppercased() == "TRUE"
//    }
    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self = ldapRaw.firstValue?.uppercased() == "TRUE"
    }
}

extension FixedWidthInteger where Self: LDAPValue {
    public var ldapRaw: LDAPRaw { String(self).ldapRaw }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self.init(String(fromLDAPRaw: ldapRaw))!
//    }
    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self.init(ldapRaw.firstValue!)!
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
    public var ldapRaw: LDAPRaw { String(self).ldapRaw }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self.init(String(fromLDAPRaw: ldapRaw))!
//    }

    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self.init(ldapRaw.firstValue!)!
    }
}

extension Double: LDAPValue {}
extension Float: LDAPValue {}

extension Optional: LDAPValue where Wrapped: LDAPValue {
    public var ldapRaw: LDAPRaw {
        map(\.ldapRaw) ?? ._empty
//        map { AnyRandomAccessCollection($0.ldapRaw) } ?? AnyRandomAccessCollection(EmptyCollection<String>())
    }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self = ldapRaw.isEmpty ? nil : Wrapped(fromLDAPRaw: ldapRaw)
//    }

    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self = ldapRaw.firstValue.map { Wrapped(fromLDAPRaw: .init($0)) }
    }
}

extension Sequence where Self: LDAPValue, Element: LDAPValue {
    public var ldapRaw: LDAPRaw { .init(map(\.ldapRaw)) }
}

extension Array: LDAPValue where Element: LDAPValue {
//    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self = ldapRaw.map { Element(fromLDAPRaw: CollectionOfOne($0)) }
//    }

    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self = ldapRaw._storage.map { Element(fromLDAPRaw: .init($0)) }
    }
}

extension ContiguousArray: LDAPValue where Element: LDAPValue {
//    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self.init()
//        reserveCapacity(ldapRaw.count)
//        for elem in ldapRaw {
//            append(.init(fromLDAPRaw: CollectionOfOne(elem)))
//        }
//    }
    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self.init()
        reserveCapacity(ldapRaw._storage.count)
        for elem in ldapRaw._storage {
            append(.init(fromLDAPRaw: .init(elem)))
        }
    }
}

extension Set: LDAPValue where Element: LDAPValue {
//    public var ldapRaw: some LDAPRaw { flatMap { $0.ldapRaw } }

//    public init<Raw: LDAPRaw>(fromLDAPRaw ldapRaw: Raw) {
//        self.init(minimumCapacity: ldapRaw.count)
//        for elem in ldapRaw {
//            insert(.init(fromLDAPRaw: CollectionOfOne(elem)))
//        }
//    }

    public init(fromLDAPRaw ldapRaw: LDAPRaw) {
        self.init(minimumCapacity: ldapRaw._storage.count)
        for elem in ldapRaw._storage {
            insert(.init(fromLDAPRaw: .init(elem)))
        }
    }
}
