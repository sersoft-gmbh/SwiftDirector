import CLDAP
#if canImport(Darwin)
import Darwin.C
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(ucrt)
import ucrt
#endif

#if compiler(>=6.2)
/// Represents a connection to an LDAP server.
@safe
public final class LDAPConnection {
    private let handle: OpaquePointer
    private var mode: Mode

    @usableFromInline
    init(duplicating original: LDAPConnection) throws {
        mode = .duplicate(original: original, isDestroyed: false)
        unsafe handle = unsafe try LDAPError.validate {
            unsafe $0 = unsafe ldap_dup(original.handle)
            return errno
        }
    }

    @usableFromInline
    init(server: LDAPServer) throws {
        mode = .primary(server, isClosed: false)
        unsafe handle = try LDAPError.validate {
            unsafe ldap_initialize(&$0, server.uri)
        }
        try LDAPError.validateVoid {
            var protVersion = LDAP_VERSION3
            return unsafe ldap_set_option(handle, LDAP_OPT_PROTOCOL_VERSION, &protVersion)
        }
    }

    deinit {
        do {
            try close()
        } catch {
            print("[SwiftDirector]: Failed to close connection on deallocation: \(error)!")
        }
    }
}
#else
/// Represents a connection to an LDAP server.
public final class LDAPConnection {
    private let handle: OpaquePointer
    private var mode: Mode

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
}
#endif

extension LDAPConnection {
    private enum Mode {
        case primary(LDAPServer, isClosed: Bool)
        // We keep a reference to the original connection to make sure we're not accidentially closed.
        case duplicate(original: LDAPConnection, isDestroyed: Bool)
    }

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
                // This might actually be wrong - if we're closed, our parent should stay functional.
                // original.isValid = newValue
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

    /// Closes (invalidates) this connection.
    /// If this connection is a primary connection (non-duplicate), it will be unbound.
    /// If this is a duplicate connection, it will be destroyed.
    /// - Throws: Any ``LDAPError`` occuring during unbinding / destroying.
    /// - SeeAlso: ``LDAPConnection/unbind()``
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
#if compiler(>=6.2)
        try LDAPError.validateVoid { unsafe ldap_destroy(handle) }
#else
        try LDAPError.validateVoid { ldap_destroy(handle) }
#endif
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
#if compiler(>=6.2)
            let copiedCredentials = unsafe strdup(credentials)
            defer { if let creds = unsafe copiedCredentials { unsafe free(creds) } }
            var creds = unsafe berval(bv_len: numericCast(credentials.utf8.count), bv_val: copiedCredentials)
            return unsafe ldap_sasl_bind_s(handle, dn.rawValue, nil, &creds, nil, nil, nil)
#else
            let copiedCredentials = strdup(credentials)
            defer { if let creds = copiedCredentials { free(creds) } }
            var creds = berval(bv_len: numericCast(credentials.utf8.count), bv_val: copiedCredentials)
            return ldap_sasl_bind_s(handle, dn.rawValue, nil, &creds, nil, nil, nil)
#endif
        }
    }

    /// Unbinds this connection invalidating it.
    /// - Throws: An ``LDAPError`` if unbinding fails.
    /// - Note: The connection cannot be used after this operation.
    public func unbind() throws {
        try LDAPError.validateVoid {
#if compiler(>=6.2)
            unsafe ldap_unbind_ext_s(handle, nil, nil)
#else
            ldap_unbind_ext_s(handle, nil, nil)
#endif
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
                                    filteredBy filter: String? = nil) throws -> Array<LDAPObject<ObjectClass>> {
        func readAttributes(entryPtr: OpaquePointer) -> Dictionary<AttributeKey, Array<String>> {
            func readValues(attributeKey: UnsafePointer<CChar>) -> Array<String>? {
#if compiler(>=6.2)
                guard let valuesPtr = unsafe ldap_get_values_len(handle, entryPtr, attributeKey) else { return nil }
                defer { unsafe ldap_value_free_len(valuesPtr) }
                return unsafe UnsafeMutableBufferPointer(start: valuesPtr, count: numericCast(ldap_count_values_len(valuesPtr))).compactMap {
                    unsafe $0.map { unsafe String(cString: $0.pointee.bv_val) }
                }
#else
                guard let valuesPtr = ldap_get_values_len(handle, entryPtr, attributeKey) else { return nil }
                defer { ldap_value_free_len(valuesPtr) }
                return UnsafeMutableBufferPointer(start: valuesPtr, count: numericCast(ldap_count_values_len(valuesPtr))).compactMap {
                    $0.map { String(cString: $0.pointee.bv_val) }
                }
#endif
            }
            var attrPtr: OpaquePointer?
#if compiler(>=6.2)
            guard let firstAttrKey = unsafe ldap_first_attribute(handle, entryPtr, &attrPtr) else { return [:] }
            return unsafe sequence(first: firstAttrKey, next: { [handle] _ in unsafe ldap_next_attribute(handle, entryPtr, attrPtr) })
                .reduce(into: [:]) { dict, ptr in
                    defer { unsafe free(ptr) }
                    unsafe dict[.init(rawValue: String(cString: ptr))] = unsafe readValues(attributeKey: ptr)
                }
#else
            guard let firstAttrKey = ldap_first_attribute(handle, entryPtr, &attrPtr) else { return [:] }
            return sequence(first: firstAttrKey, next: { [handle] _ in ldap_next_attribute(handle, entryPtr, attrPtr) })
                .reduce(into: [:]) { dict, ptr in
                    defer { free(ptr) }
                    dict[.init(rawValue: String(cString: ptr))] = readValues(attributeKey: ptr)
                }
#endif
        }

        assertValid()
        let objectClassFilter = "(objectClass=\(objectClass.oid))"
        let actualFilter = filter.map { "(&\(objectClassFilter)\($0))" } ?? objectClassFilter
#if compiler(>=6.2)
        let result = unsafe try LDAPError.validate(freeingWith: { unsafe ldap_msgfree($0) }) { resultPtr in
            unsafe [LDAP_ALL_USER_ATTRIBUTES, LDAP_ALL_OPERATIONAL_ATTRIBUTES].withMutableArrayOfCStrings {
                unsafe $0.withUnsafeMutableBufferPointer {
                    unsafe ldap_search_ext_s(handle, base, LDAP_SCOPE_CHILDREN, actualFilter, $0.baseAddress, 0, nil, nil, nil, .max, &resultPtr)
                }
            }
        }
        defer { unsafe ldap_msgfree(result) }
        guard let firstEntry = unsafe ldap_first_entry(handle, result) else { return [] }
        return unsafe sequence(first: firstEntry, next: { [handle] in unsafe ldap_next_entry(handle, $0) }).map {
            unsafe .init(rawAttributes: readAttributes(entryPtr: $0))
        }
#else
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
            .init(rawAttributes: readAttributes(entryPtr: $0))
        }
#endif
    }
}

@available(*, unavailable)
extension LDAPConnection: Sendable {}

fileprivate extension Collection where Element == String {
    func withMutableArrayOfCStrings<R, E: Error>(_ body: (inout Array<UnsafeMutablePointer<CChar>?>) throws(E) -> R) throws(E) -> R {
#if compiler(>=6.2)
        var cStrings = unsafe map { unsafe strdup($0) } + CollectionOfOne(nil)
        defer { unsafe cStrings.lazy.compactMap { unsafe $0 }.forEach { unsafe free($0) } }
        return try unsafe body(&cStrings)
#else
        var cStrings = map { strdup($0) } + CollectionOfOne(nil)
        defer { cStrings.lazy.compactMap { $0 }.forEach { free($0) } }
        return try body(&cStrings)
#endif
    }
}
