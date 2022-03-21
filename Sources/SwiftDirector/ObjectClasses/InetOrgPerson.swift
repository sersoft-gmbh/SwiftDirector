public protocol InetOrgPersonProtocol: OrganizationalPersonProtocol {}

extension InetOrgPersonProtocol {
    public var userID: Attribute<String?> { .init(key: "uid") }
    public var mail: Attribute<String?> { .init(key: "mail") }
    public var givenName: Attribute<String?> { .init(key: "givenName") }
    public var displayName: Attribute<String?> { .init(key: "displayName") }
    public var employeeNumber: Attribute<String?> { .init(key: "employeeNumber") }
}

@frozen
public struct InetOrgPerson: InetOrgPersonProtocol {
    public typealias ID = DistinguishedName

    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public static var oid: String { "2.16.840.1.113730.3.2.2" }
    public static var name: String { "inetOrgPerson" }
    
    public init() {}
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension InetOrgPerson: Sendable {}
#endif
