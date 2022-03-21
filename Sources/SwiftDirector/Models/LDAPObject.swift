/// Represents a concrete object of a given object class type. This type can be used to extract attributes for this object.
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

    /// Checks whether this object has the given attribute.
    /// - Parameter attributePath: The path for the attribute.
    /// - Returns: `true` if this object has the given attribute, `false` otherwise.
    @inlinable
    public func hasAttribute<T>(_ attributePath: KeyPath<ObjectClass, Attribute<T>>) -> Bool {
        storage.hasAttribute(metaObjectClass[keyPath: attributePath])
    }

    /// Checks whether this object can be casted to the given other object class.
    /// - Parameter other: The other object class type against which to check castability.
    /// - Returns: `true` if this object can be casted to the other object class type, `false` otherwise.
    public func canCast<C: ObjectClassProtocol>(to other: C.Type) -> Bool {
        guard other != ObjectClass.self else { return true }
        guard hasAttribute(\.objectClasses) else { return false }
        let objectClasses = self.objectClasses
        return objectClasses.contains(other.name) || objectClasses.contains(other.oid)
    }

    @usableFromInline
    func uncheckedForceCast<C: ObjectClassProtocol>(to other: C.Type) -> LDAPObject<C> {
        LDAPObject<C>(storage: storage)
    }

    /// Force casts this object to new object class type.
    /// - Parameter other: The new object class type to force cast to.
    /// - Returns: The new object of the new object class type.
    /// - Precondition: This object must be castable to the new type.
    ///                 Otherwise an assertion is triggered in debug builds and in release builds accessing attributes on the new object results in undefined behavior.
    @inlinable
    public func forceCast<C: ObjectClassProtocol>(to other: C.Type = C.self) -> LDAPObject<C> {
        assert(canCast(to: other))
        return uncheckedForceCast(to: other)
    }

    /// Casts this object to a new object class type if possible.
    /// - Parameter other: The new object class type to use.
    /// - Returns: The new object of the new object class type or nil if the receiver is not castable to the new object class type.
    /// - SeeAlso: `canCast(to:)`
    @inlinable
    public func cast<C: ObjectClassProtocol>(to other: C.Type = C.self) -> LDAPObject<C>? {
        canCast(to: other) ? uncheckedForceCast(to: other) : nil
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

#if compiler(>=5.5) && canImport(_Concurrency)
extension LDAPObjectStorage: @unchecked Sendable {}
extension LDAPObject: Sendable where ObjectClass: Sendable {}
#endif
