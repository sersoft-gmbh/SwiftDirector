@dynamicMemberLookup
public struct LDAPObject<ObjectClass: ObjectClassProtocol> {
    private let objectClass = ObjectClass()
    private let storage: [AttributeKey: Any]

    public var entryDN: String { extractValue(for: Attribute(key: "entryDN")) }

    init(storage: [AttributeKey: Any]) {
        self.storage = storage
    }

    private func extractValue<T>(for attribute: Attribute<T>) -> T {
        storage[attribute.key] as! T
    }

    public subscript<T>(dynamicMember path: KeyPath<ObjectClass, Attribute<T>>) -> T {
        extractValue(for: objectClass[keyPath: path])
    }
}
