fileprivate extension AttributeKey {
    static let entryDN: AttributeKey = "entryDN"
}

@dynamicMemberLookup
public struct LDAPObject<ObjectClass: ObjectClassProtocol> {
    private final class Storage {
        private var raw: [AttributeKey: [String]]
        private var cache: [AttributeKey: Any]

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
                guard let rawValue = raw[attribute.key] else {
                    if let null = Optional<Any>.none as? T {
                        cache[attribute.key] = null
                        return null
                    }
                    fatalError("Attribute with key \(attribute.key) is not present in object of object class \(ObjectClass.self)!")
                }
                let converted = T(fromLDAPRaw: rawValue)
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

    public var entryDN: String {
        get { self[Attribute(key: .entryDN)] }
        set { self[Attribute(key: .entryDN)] = newValue }
    }

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
}
