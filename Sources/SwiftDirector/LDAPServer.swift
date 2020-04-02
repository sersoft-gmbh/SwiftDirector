import CLDAP

public struct LDAPServer: Hashable {
    public enum Schema: Hashable {
        case ldap, ldaps
        case ldapi, cldap
        case custom(String)

        @usableFromInline
        var schemeString: String {
            switch self {
            case .ldap: return "ldap"
            case .ldaps: return "ldaps"
            case .ldapi: return "ldapi"
            case .cldap: return "cldap"
            case .custom(let str): return str
            }
        }
    }

    public var schema: Schema
    public var host: String
    public var port: UInt16

    @inlinable
    var uri: String { schema.schemeString + "://" + host + ":" + String(port) }

    public init(schema: Schema, host: String, port: UInt16) {
        self.schema = schema
        self.host = host
        self.port = port
    }

    @inlinable
    public func openConnection() throws -> LDAPConnection { try .init(server: self) }
}

extension LDAPServer {
    @inlinable
    public static func ldap(host: String, port: UInt16 = numericCast(LDAP_PORT)) -> Self {
        .init(schema: .ldap, host: host, port: port)
    }

    @inlinable
    public static func ldaps(host: String, port: UInt16 = numericCast(LDAPS_PORT)) -> Self {
        .init(schema: .ldaps, host: host, port: port)
    }
}
