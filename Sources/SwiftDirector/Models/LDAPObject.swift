@dynamicMemberLookup
public struct LDAPObject<ObjectClass: ObjectClassProtocol>: Equatable, Hashable, Identifiable, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias ID = ObjectClass.ID

    /*private but*/ @usableFromInline let metaObjectClass = ObjectClass()
    /*private but*/ @usableFromInline private(set) var storage: LDAPObjectStorage

    @inlinable
    public var id: ID { self[dynamicMember: ObjectClass.idPath] }

    public var description: String { description(includeCache: false) }
    public var debugDescription: String { description(includeCache: true) }

    private init(storage: LDAPObjectStorage) {
        self.storage = storage
    }

    init(rawAttributes: [AttributeKey: [String]]) {
        self.init(storage: .init(raw: rawAttributes))
    }

    /*private but*/ @usableFromInline subscript<T>(_ attribute: Attribute<T>) -> T {
        @inlinable get { storage[attribute] }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.copy()
            }
            storage[attribute] = newValue
        }
    }

    @inlinable
    public subscript<T>(dynamicMember path: KeyPath<ObjectClass, Attribute<T>>) -> T {
        get { self[metaObjectClass[keyPath: path]] }
        set { self[metaObjectClass[keyPath: path]] = newValue }
    }

    @inlinable
    public func hasAttribute<T>(_ attributePath: KeyPath<ObjectClass, Attribute<T>>) -> Bool {
        storage.hasAttribute(metaObjectClass[keyPath: attributePath])
    }

    public func canCast<C: ObjectClassProtocol>(to other: C.Type) -> Bool {
        guard other != ObjectClass.self else { return true }
        guard hasAttribute(\.objectClass) else { return false }
        let objectClasses = self.objectClass
        return objectClasses.contains(other.name) || objectClasses.contains(other.oid)
    }

    public func forceCast<C: ObjectClassProtocol>(to other: C.Type = C.self) -> LDAPObject<C> {
        LDAPObject<C>(storage: storage)
    }

    @inlinable
    public func cast<C: ObjectClassProtocol>(to other: C.Type = C.self) -> LDAPObject<C>? {
        canCast(to: other) ? forceCast(to: other) : nil
    }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private func description(includeCache: Bool) -> String {
        let idAttrKey = metaObjectClass[keyPath: ObjectClass.idPath].key
        func description<V>(for dict: [AttributeKey: V], indent: Int) -> String {
            dict.sorted { $0.key < $1.key }
                .lazy
                .filter { $0.key != idAttrKey }
                .map { "- \($0.key): \($0.value)" }
                .joined(separator: "\n" + repeatElement(" ", count: indent))
        }
        let baseDesc = """
        \(ObjectClass.displayName) (\(ObjectClass.oid)):
           ID (\(idAttrKey)): \(id)
           Attributes:
              \(description(for: storage.raw, indent: 6))
        """
        guard includeCache else { return baseDesc }
        return baseDesc + "\n   Cache:\n" + description(for: storage.cache, indent: 6)
    }

    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

// Needs to be defined outside the LDAPObject generic object to be able to pass it on.
/*fileprivate but*/ @usableFromInline final class LDAPObjectStorage {
    fileprivate private(set) var raw: [AttributeKey: [String]]
    fileprivate private(set) var cache: [AttributeKey: Any]

    private init(raw: [AttributeKey: [String]], cache: [AttributeKey: Any]) {
        self.raw = raw
        self.cache = cache
    }

    fileprivate convenience init(raw: [AttributeKey: [String]]) {
        self.init(raw: raw, cache: [:])
    }

    fileprivate func copy() -> LDAPObjectStorage { .init(raw: raw, cache: cache) }

    @usableFromInline
    subscript<T>(_ attribute: Attribute<T>) -> T {
        get {
            if let cachedValue = cache[attribute.key] {
                return cachedValue as! T
            }
            let converted = raw[attribute.key].map(T.init) ?? T(fromLDAPRaw: EmptyCollection())
            cache[attribute.key] = converted
            return converted
        }
        set {
            cache[attribute.key] = newValue
            raw[attribute.key] = Array(newValue.ldapRaw)
        }
    }

    @usableFromInline
    func hasAttribute<T>(_ attribute: Attribute<T>) -> Bool {
        raw.keys.contains(attribute.key)
    }
}
