public protocol GroupOfNamesProtocol: TopObjectClassProtocol {}

extension GroupOfNamesProtocol {
    public var commonName: Attribute<String> { .init(key: "cn") }

    // Is "MAY" in some LDAP implementations - however in our implementation will lead to an empty array.
    public var member: Attribute<Array<DistinguishedName>> { .init(key: "member") }

    public var organization: Attribute<String?> { .init(key: "o") }
    public var organizationalUnit: Attribute<String?> { .init(key: "ou") }
    public var owner: Attribute<DistinguishedName?> { .init(key: "owner") }
}

@frozen
public struct GroupOfNames: GroupOfNamesProtocol {
    public static var oid: String { "2.5.6.9" }
    public static var name: String { "groupOfNames" }

    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public init() {}
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension GroupOfNames: Sendable {}
#endif
