/// Represents any object class.
public struct AnyObjectClass: ObjectClassProtocol {
    public static var oid: String { "*" }
    public static var name: String { "*" }

    public init() {}
}
