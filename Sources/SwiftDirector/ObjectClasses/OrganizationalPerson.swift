public protocol OrganizationalPersonProtocol: TopObjectClassProtocol {}

extension OrganizationalPersonProtocol {
    public var title: Attribute<String?> { .init(key: "title") }
    public var organizationalUnit: Attribute<String?> { .init(key: "ou") }

    public var street: Attribute<String?> { .init(key: "street") }
    public var postalAddress: Attribute<String?> { .init(key: "postalAddress") }
    public var postalCode: Attribute<String?> { .init(key: "postalCode") }
}

@frozen
public struct OrganizationalPerson: OrganizationalPersonProtocol {
    public typealias ID = DistinguishedName

    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public static var oid: String { "2.5.6.7" }
    public static var name: String { "organizationalPerson" }
    
    public init() {}
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension OrganizationalPerson: Sendable {}
#endif
