public protocol InetOrgPersonProtocol: OrganizationalPersonProtocol {}

extension InetOrgPersonProtocol {
    public var userID: Attribute<String?> { .init(key: "uid") }
    public var mail: Attribute<String?> { .init(key: "mail") }
    public var givenName: Attribute<String?> { .init(key: "givenName") }
    public var displayName: Attribute<String?> { .init(key: "displayName") }
    public var employeeNumber: Attribute<String?> { .init(key: "employeeNumber") }
}

public struct InetOrgPerson: InetOrgPersonProtocol {
    public static var oid: String { "2.16.840.1.113730.3.2.2" }
    
    public init() {}
}
