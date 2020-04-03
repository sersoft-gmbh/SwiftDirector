public protocol TopObjectClassProtocol: ObjectClassProtocol {}

public struct TopObjectClass: TopObjectClassProtocol {
    public static var oid: String { "2.5.6.0" }
    public static var name: String { "top" }

    public init() {}
}
