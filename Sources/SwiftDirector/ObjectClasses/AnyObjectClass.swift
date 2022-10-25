/// Represents any object class.
@frozen
public struct AnyObjectClass: ObjectClassProtocol {
    public static var oid: String { "*" }
    public static var name: String { "*" }

    @inlinable
    public static var idPath: IDPath { \.entryDN }

    public init() {}
}
