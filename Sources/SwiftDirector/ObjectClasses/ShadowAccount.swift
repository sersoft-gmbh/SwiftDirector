public protocol ShadowAccountProtocol: TopObjectClassProtocol {}

extension ShadowAccountProtocol {
    public var userID: Attribute<String> { .init(key: "uid") }

    public var authPassword: Attribute<String?> { .init(key: "authPassword") }

    public var shadowLastChange: Attribute<Int?> { .init(key: "shadowLastChange") }
    public var shadowMin: Attribute<Int?> { .init(key: "shadowMin") }
    public var shadowMax: Attribute<Int?> { .init(key: "shadowMax") }
    public var shadowInactive: Attribute<Int?> { .init(key: "shadowInactive") }
    public var shadowWarning: Attribute<Int?> { .init(key: "shadowWarning") }
}

@frozen
public struct ShadowAccount: ShadowAccountProtocol {
    public static var oid: String { "1.3.6.1.1.1.2.1" }
    public static var name: String { "shadowAccount" }
    
    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public init() {}
}

#if compiler(>=5.5) && canImport(_Concurrency)
extension ShadowAccount: Sendable {}
#endif
