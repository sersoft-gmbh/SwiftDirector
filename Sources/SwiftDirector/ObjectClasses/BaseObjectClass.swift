/// The base protocol for all object classes.
/// New object classes should always declare a protocol (MyObjectClassProtocol) and a corresponding implementation (MyObjectClass).
/// However, the implementation should alway just be an empty struct just containing the oid and the protocol should have all properties defined in an extension.
/// See e.g. ``OrganizationalPerson``.
public protocol ObjectClassProtocol<ID>: Sendable {
    /// The type of the identifier of object of this object class.
    associatedtype ID: Hashable, LDAPValue = DistinguishedName

    typealias IDPath = KeyPath<Self, Attribute<ID>>

    /// The numeric identifier of this object class.
    static var oid: String { get }
    /// The name of this object class (e.g. top or shadowAccount).
    static var name: String { get }
    /// The path to the identifying attribute of this object class. Defaults to the ``entryDN`` if ``ID`` is ``DistinguishedName``.
    static var idPath: IDPath { get }

    /// Creates a new instance of the object class. The object class is just a descriptor and should thus not have any fields and the initializer should not do anything.
    init()
}

extension ObjectClassProtocol {
    /// The entry's distinguished name.
    public var entryDN: Attribute<DistinguishedName> { .init(key: "entryDN") }
    /// The object classes this entry conforms to.
    public var objectClasses: Attribute<Array<String>> { .init(key: "objectClass") }

    /// The distinguished names of groups this object belongs to.
    public var memberOf: Attribute<Array<DistinguishedName>> { .init(key: "memberOf") }
}

extension ObjectClassProtocol where ID == DistinguishedName {
    @inlinable
    public static var idPath: IDPath { \.entryDN }
}

extension ObjectClassProtocol {
    /// The display name of this object class.
    public static var displayName: String {
        let ldapName = name
        assert(!ldapName.isEmpty, "Object class \(Self.self) has an empty name!")
        guard !ldapName.isEmpty else { return ldapName }
        return ldapName[ldapName.startIndex].uppercased() + ldapName.dropFirst()
    }
}
