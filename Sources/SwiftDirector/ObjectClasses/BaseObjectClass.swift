/// The base protocol for all object classes.
/// New object classes should always declare a protocol (MyObjectClassProtocol) and a corresponding implementation (MyObjectClass).
/// However, the implementation should alway just be an empty struct just containing the oid and the protocol should have all properties defined in an extension.
/// See e.g. OrganizationalPerson.
public protocol ObjectClassProtocol {
    static var oid: String { get }

    init()
}

public protocol TopObjectClassProtocol: ObjectClassProtocol {}

public struct TopObjectClass: TopObjectClassProtocol {
    public static var oid: String { "2.5.6.0" }

    public init() {}
}
