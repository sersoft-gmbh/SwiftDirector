/// The base protocol for all object classes.
/// New object classes should always declare a protocol (MyObjectClassProtocol) and a corresponding implementation (MyObjectClass).
/// However, the implementation should alway just be an empty struct just containing the oid and the protocol should have all properties defined in an extension.
/// See e.g. OrganizationalPerson.
public protocol ObjectClassProtocol {
    associatedtype ID: Hashable, LDAPValue = String
    typealias IDPath = KeyPath<Self, Attribute<ID>>

    static var oid: String { get }
    static var name: String { get }
    static var idPath: IDPath { get }

    init()
}

extension ObjectClassProtocol {
    public var entryDN: Attribute<String> { .init(key: "entryDN") }
    public var objectClass: Attribute<Array<String>> { .init(key: "objectClass") }

    // Actually not always present, but will be an empty array in this case.
    public var memberOf: Attribute<Array<String>> { .init(key: "memberOf") }
}

extension ObjectClassProtocol where ID == String {
    @inlinable
    public static var idPath: IDPath { \.entryDN }
}

extension ObjectClassProtocol {
    public static var displayName: String {
        let ldapName = name
        assert(!ldapName.isEmpty, "Object class \(Self.self) has an empty name!")
        guard !ldapName.isEmpty else { return ldapName }
        return ldapName[ldapName.startIndex].uppercased() + ldapName.dropFirst()
    }
}

public protocol TopObjectClassProtocol: ObjectClassProtocol {}

public struct TopObjectClass: TopObjectClassProtocol {
    public static var oid: String { "2.5.6.0" }
    public static var name: String { "top" }

    public init() {}
}
