@dynamicMemberLookup
public struct LDAPObject<ObjectClass: ObjectClassProtocol>: Equatable, Hashable, Identifiable, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias ID = ObjectClass.ID

    private final class Storage {
        private(set) var raw: [AttributeKey: [String]]
        private(set) var cache: [AttributeKey: Any]

        private init(raw: [AttributeKey: [String]], cache: [AttributeKey: Any]) {
            self.raw = raw
            self.cache = cache
        }

        convenience init(raw: [AttributeKey: [String]]) {
            self.init(raw: raw, cache: [:])
        }

        func copy() -> Storage { .init(raw: raw, cache: cache) }

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
    }

    private let objectClass = ObjectClass()
    private var storage: Storage

    @inlinable
    public var id: ID { self[dynamicMember: ObjectClass.idPath] }

    public var description: String { description(includeCache: false) }
    public var debugDescription: String { description(includeCache: true) }

    init(storage: [AttributeKey: [String]]) {
        self.storage = .init(raw: storage)
    }

    private subscript<T>(_ attribute: Attribute<T>) -> T {
        get { storage[attribute] }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.copy()
            }
            storage[attribute] = newValue
        }
    }

    public subscript<T>(dynamicMember path: KeyPath<ObjectClass, Attribute<T>>) -> T {
        get { self[objectClass[keyPath: path]] }
        set { self[objectClass[keyPath: path]] = newValue }
    }

    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private func description(includeCache: Bool) -> String {
        let idAttrKey = objectClass[keyPath: ObjectClass.idPath].key
        func description<V>(for dict: [AttributeKey: V], indent: Int) -> String {
            dict.sorted { $0.key < $1.key }
                .lazy
                .filter { $0.key != idAttrKey }
                .map { "- \($0.key): \($0.value)" }
                .joined(separator: "\n" + repeatElement(" ", count: indent))
        }
        let baseDesc = """
        \(ObjectClass.self) (\(ObjectClass.oid)):
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
