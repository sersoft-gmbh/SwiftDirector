public protocol TopObjectClassProtocol: ObjectClassProtocol {}

@frozen
public struct TopObjectClass: TopObjectClassProtocol {
    public static var oid: String { "2.5.6.0" }
    public static var name: String { "top" }

    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public init() {}
}
