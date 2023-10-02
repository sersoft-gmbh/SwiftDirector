public protocol PersonProtocol: TopObjectClassProtocol {}

extension PersonProtocol {
    public var commonName: Attribute<String> { .init(key: "cn") }
    public var surname: Attribute<String> { .init(key: "sn") }

    public var givenName: Attribute<String?> { .init(key: "givenName") }
    public var initials: Attribute<String?> { .init(key: "initials") }
    public var fullName: Attribute<String?> { .init(key: "fullName") }
    public var preferredName: Attribute<String?> { .init(key: "preferredName") }
    public var userID: Attribute<String?> { .init(key: "uid") }
    public var userPassword: Attribute<String?> { .init(key: "userPassword") }
}

@frozen
public struct Person: PersonProtocol {
    public typealias ID = DistinguishedName

    public static var oid: String { "2.5.6.6" }
    public static var name: String { "person" }

    public init() {}
}
