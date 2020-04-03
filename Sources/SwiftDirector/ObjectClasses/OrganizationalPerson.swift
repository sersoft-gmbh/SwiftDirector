public protocol OrganizationalPersonProtocol: TopObjectClassProtocol {}

extension OrganizationalPersonProtocol {
    public var title: Attribute<String?> { .init(key: "title") }
    public var organizationalUnit: Attribute<String?> { .init(key: "ou") }

    public var street: Attribute<String?> { .init(key: "street") }
    public var postalAddress: Attribute<String?> { .init(key: "postalAddress") }
    public var postalCode: Attribute<String?> { .init(key: "postalCode") }
}

public struct OrganizationalPerson: OrganizationalPersonProtocol {
    public static var oid: String { "2.5.6.7" }
    public static var name: String { "organizationalPerson" }
    
    public init() {}
}
