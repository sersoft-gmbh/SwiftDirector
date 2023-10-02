public protocol GroupOfUniqueNamesProtocol: TopObjectClassProtocol {}

extension GroupOfUniqueNamesProtocol {
    public var commonName: Attribute<String> { .init(key: "cn") }

    // Is actually "MAY" - however in our implementation will lead to an empty array.
    public var uniqueMember: Attribute<Array<DistinguishedName>> { .init(key: "uniqueMember") }

    public var organization: Attribute<String?> { .init(key: "o") }
    public var organizationalUnit: Attribute<String?> { .init(key: "ou") }
    public var owner: Attribute<DistinguishedName?> { .init(key: "owner") }
}

@frozen
public struct GroupOfUniqueNames: GroupOfUniqueNamesProtocol {
    public typealias ID = DistinguishedName

    public static var oid: String { "2.5.6.17" }
    public static var name: String { "groupOfUniqueNames" }

    public init() {}
}
