import CLDAP

/// Represents a server configuration.
public struct LDAPServer: Hashable {
    /// The schema to use for connecting to the LDAP.
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

    /// The schema to use for connecting.
    public var schema: Schema
    /// The host to connect to.
    public var host: String
    /// The port to use for connecting.
    public var port: UInt16

    @inlinable
    var uri: String { schema.schemeString + "://" + host + ":" + String(port) }

    /// Creates a new server configuration with the given schema, host and port.
    /// - Parameters:
    ///   - schema: The schema to use for the configuration.
    ///   - host: The host to use for the configuration.
    ///   - port: The port to use for the configuration.
    public init(schema: Schema, host: String, port: UInt16) {
        self.schema = schema
        self.host = host
        self.port = port
    }

    /// Opens a new connection to this server.
    /// - Throws: Any `LDAPError` happening during connection.
    /// - Returns: The new `LDAPConnection` to this server.
    @inlinable
    public func openConnection() throws -> LDAPConnection { try .init(server: self) }
}

extension LDAPServer {
    /// A new server configuration with `.ldap` scheme and LDAP_PORT as default port.
    /// - Parameters:
    ///   - host: The host for this configuration.
    ///   - port: The port to use. Defaults to LDAP_PORT.
    /// - Returns: The new server configuration.
    @inlinable
    public static func ldap(host: String, port: UInt16 = numericCast(LDAP_PORT)) -> Self {
        .init(schema: .ldap, host: host, port: port)
    }

    /// A new server configuration with `.ldaps` scheme and LDAPS_PORT as default port.
    /// - Parameters:
    ///   - host: The host for this configuration.
    ///   - port: The port to use. Defaults to LDAPS_PORT.
    /// - Returns: The new server configuration.
    @inlinable
    public static func ldaps(host: String, port: UInt16 = numericCast(LDAPS_PORT)) -> Self {
        .init(schema: .ldaps, host: host, port: port)
    }
}
