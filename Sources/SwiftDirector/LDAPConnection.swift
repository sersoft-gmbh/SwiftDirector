import CLDAP
#if canImport(Darwin)
import Darwin.C
#elseif canImport(Glibc)
import Glibc
#endif

/// Represents a connection to an LDAP server.
public final class LDAPConnection {
    private enum Mode {
        case primary(LDAPServer, isClosed: Bool)
        // We keep a reference to the original connection to make sure we're not accidentially closed.
        case duplicate(original: LDAPConnection, isDestroyed: Bool)
    }

    private let handle: OpaquePointer
    private var mode: Mode

    private var isValid: Bool {
        get {
            switch mode {
            case .primary(_, let isClosed): return !isClosed
            case .duplicate(let original, let isDestroyed): return !isDestroyed && original.isValid
            }
        }
        set {
            switch mode {
            case .primary(let server, _):
                mode = .primary(server, isClosed: !newValue)
            case .duplicate(let original, _):
                mode = .duplicate(original: original, isDestroyed: !newValue)
                original.isValid = newValue
            }
        }
    }

    /// The server this connection is connected to.
    public var server: LDAPServer {
        switch mode {
        case .primary(let server, _): return server
        case .duplicate(let original, _): return original.server
        }
    }

    public var isDuplicate: Bool {
        switch mode {
        case .primary(_, _): return false
        case .duplicate(_, _): return true
        }
    }

    @usableFromInline
    init(duplicating original: LDAPConnection) throws {
        mode = .duplicate(original: original, isDestroyed: false)
        handle = try LDAPError.validate {
            $0 = ldap_dup(original.handle)
            return errno
        }
    }

    @usableFromInline
    init(server: LDAPServer) throws {
        mode = .primary(server, isClosed: false)
        handle = try LDAPError.validate {
            ldap_initialize(&$0, server.uri)
        }
        try LDAPError.validateVoid {
            var protVersion = LDAP_VERSION3
            return ldap_set_option(handle, LDAP_OPT_PROTOCOL_VERSION, &protVersion)
        }
    }

    deinit {
        do {
            try close()
        } catch {
            print("[SwiftDirector]: Failed to close connection on deallocation: \(error)!")
        }
    }

    /// Closes (invalidates) this connection.
    /// If this connection is a primary connection (non-duplicate), it will be unbound.
    /// If this is a duplicate connection, it will be destroyed.
    /// - Throws: Any ``LDAPError`` occuring during unbinding / destroying.
    /// - SeeAlso: `unbind()`
    public func close() throws {
        switch mode {
        case .primary(_, let isClosed):
            guard !isClosed else { return }
            try unbind()
        case .duplicate(_, let isDestroyed):
            guard !isDestroyed else { return }
            try destroy()
        }
    }

    /// Returns a duplicated connection.
    /// - Parameter fromOriginal: Whether or not the duplicate should be made from the original connection if this connection is already a duplicate. Defaults to `false`.
    /// - Throws: An ``LDAPError`` if the duplication does not work.
    /// - Returns: A duplicated connection.
    public func duplicate(fromOriginal: Bool = false) throws -> LDAPConnection {
        guard fromOriginal, case .duplicate(let original, _) = mode
        else { return try .init(duplicating: self) }
        return try original.duplicate(fromOriginal: fromOriginal)
    }

//    @usableFromInline
    func destroy() throws {
        try LDAPError.validateVoid { ldap_destroy(handle) }
    }

    /// Creates a new primary (non-duplicate) connection based on this connection's `server`.
    /// - Throws: Any ``LDAPError`` occurring during the creation of a new connection.
    /// - Returns: A new primary (non-duplicate) connection.
    /// - SeeAlso: ``LDAPConnection/server``
    @inlinable
    public func newPrimaryConnection() throws -> LDAPConnection {
        try .init(server: server)
    }

    @inline(__always)
    private func assertValid(file: StaticString = #file, line: UInt = #line) {
        assert(isValid, "Cannot perform operations on a closed connection!", file: file, line: line)
    }

    /// Binds this connection to a given distinguishedName (``DistinguishedName``) with the given credentials.
    /// - Parameters:
    ///   - dn: The distinguished name to bind this connection to.
    ///   - credentials: The credentials to use for binding.
    /// - Throws: An ``LDAPError`` if binding fails.
    public func bind(dn: DistinguishedName, credentials: String) throws {
        assertValid()
        try LDAPError.validateVoid {
            let copiedCredentials = strdup(credentials)
            defer { if let creds = copiedCredentials { free(creds) } }
            var creds = berval(bv_len: numericCast(credentials.utf8.count), bv_val: copiedCredentials)
            return ldap_sasl_bind_s(handle, dn.rawValue, nil, &creds, nil, nil, nil)
        }
    }

    /// Unbinds this connection invalidating it.
    /// - Throws: An `LDAPError` if unbinding fails.
    /// - Note: The connection cannot be used after this operation.
    public func unbind() throws {
        try LDAPError.validateVoid {
            ldap_unbind_ext_s(handle, nil, nil)
        }
        isValid = false
    }

    /// Searches the directory for objects of a given object class using the given base and additional filter.
    /// - Parameters:
    ///   - objectClass: The object class type of which the resulting objects should be.
    ///   - base: The base in which to search.
    ///   - filter: Additional LDAP filters to specify. Defaults to `nil`. The method will add the filter for the object class.
    /// - Throws: An ``LDAPError`` if searching or parsing fails.
    /// - Returns: A list of ``LDAPObject``s of the given object class type.
    public func search<ObjectClass>(for objectClass: ObjectClass.Type = ObjectClass.self,
                                    inBase base: String,
                                    filteredBy filter: String? = nil) throws -> [LDAPObject<ObjectClass>] {
        func readAttributes(entryPtr: OpaquePointer) -> [AttributeKey: [String]] {
            func readValues(attributeKey: UnsafePointer<CChar>) -> [String]? {
                guard let valuesPtr = ldap_get_values_len(handle, entryPtr, attributeKey) else { return nil }
                defer { ldap_value_free_len(valuesPtr) }
                return UnsafeMutableBufferPointer(start: valuesPtr, count: numericCast(ldap_count_values_len(valuesPtr))).compactMap {
                    $0.map { String(cString: $0.pointee.bv_val) }
                }
            }
            var attrPtr: OpaquePointer?
            guard let firstAttrKey = ldap_first_attribute(handle, entryPtr, &attrPtr) else { return [:] }
            return sequence(first: firstAttrKey, next: { [handle] _ in ldap_next_attribute(handle, entryPtr, attrPtr) }).reduce(into: [:]) { dict, ptr in
                defer { free(ptr) }
                dict[.init(rawValue: String(cString: ptr))] = readValues(attributeKey: ptr)
            }
        }

        assertValid()
        let objectClassFilter = "(objectClass=\(objectClass.oid))"
        let actualFilter = filter.map { "(&\(objectClassFilter)\($0))" } ?? objectClassFilter
        let result = try LDAPError.validate(freeingWith: { ldap_msgfree($0) }) { resultPtr in
            [LDAP_ALL_USER_ATTRIBUTES, LDAP_ALL_OPERATIONAL_ATTRIBUTES].withMutableArrayOfCStrings {
                $0.withUnsafeMutableBufferPointer {
                    ldap_search_ext_s(handle, base, LDAP_SCOPE_CHILDREN, actualFilter, $0.baseAddress, 0, nil, nil, nil, .max, &resultPtr)
                }
            }
        }
        defer { ldap_msgfree(result) }
        guard let firstEntry = ldap_first_entry(handle, result) else { return [] }
        return sequence(first: firstEntry, next: { [handle] in ldap_next_entry(handle, $0) }).map {
            return .init(rawAttributes: readAttributes(entryPtr: $0))
        }
    }
}

fileprivate extension Collection where Element == String {
    func withMutableArrayOfCStrings<R>(_ body: (inout [UnsafeMutablePointer<CChar>?]) throws -> R) rethrows -> R {
        var cStrings = map { strdup($0) } + CollectionOfOne(nil)
        defer { cStrings.lazy.compactMap { $0 }.forEach { free($0) } }
        return try body(&cStrings)
    }
}
