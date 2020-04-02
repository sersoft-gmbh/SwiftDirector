import CLDAP
#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public final class LDAPConnection {
    private enum Mode {
        case primary(LDAPServer, isUnbound: Bool)
        case duplicate(original: LDAPConnection)
    }

    public var server: LDAPServer {
        switch mode {
        case .primary(let server, _): return server
        case .duplicate(let original): return original.server
        }
    }

    private var mode: Mode
    private let handle: OpaquePointer

    private var isUnbound: Bool {
        get {
            switch mode {
            case .primary(_, let isUnbound): return isUnbound
            case .duplicate(let original): return original.isUnbound
            }
        }
        set {
            switch mode {
            case .primary(let server, _):
                mode = .primary(server, isUnbound: newValue)
            case .duplicate(let original):
                original.isUnbound = newValue
            }
        }
    }

    @usableFromInline
    init(duplicating original: LDAPConnection) throws {
        mode = .duplicate(original: original)
        handle = try LDAPError.validate {
            $0 = ldap_dup(original.handle)
            return errno
        }
    }

    @usableFromInline
    init(server: LDAPServer) throws {
        mode = .primary(server, isUnbound: false)
        handle = try LDAPError.validate {
            ldap_initialize(&$0, server.uri)
        }
        try LDAPError.validateVoid {
            var protVersion = LDAP_VERSION3
            return ldap_set_option(handle, LDAP_OPT_PROTOCOL_VERSION, &protVersion)
        }
    }

    deinit {
        switch mode {
        case .primary(_, let isUnbound):
            guard !isUnbound else { return }
            do {
                try unbind()
            } catch {
                print("Failed to unbind: \(error)!")
            }
        case .duplicate(_):
            do {
                try LDAPError.validateVoid { ldap_destroy(handle) }
            } catch {
                print("Failed to destroy duplicate: \(error)")
            }
        }
    }

    @inlinable
    public func duplicate() throws -> LDAPConnection {
        try .init(duplicating: self)
    }

    @inlinable
    public func newPrimaryConnection() throws -> LDAPConnection {
        try .init(server: server)
    }

    @inline(__always)
    private func assertOpen(file: StaticString = #file, line: UInt = #line) {
        assert(!isUnbound, "Cannot perform operations on a closed connection!", file: file, line: line)
    }

    public func bind(dn: String, credentials: String) throws {
        assertOpen()
        try LDAPError.validateVoid {
            let copiedCredentials = strdup(credentials)
            defer { free(copiedCredentials) }
            var creds = berval(bv_len: numericCast(credentials.count), bv_val: copiedCredentials)
            return ldap_sasl_bind_s(handle, dn, nil, &creds, nil, nil, nil)
        }
    }

    public func unbind() throws {
        try LDAPError.validateVoid {
            ldap_unbind_ext_s(handle, nil, nil)
        }
        isUnbound = true
    }

    public func search<T>(base: String, filter: String? = nil) throws -> [LDAPObject<T>] {
        let objectClassFilter = "(objectClass=\(T.oid))"
        let actualFilter = filter.map { "(&\(objectClassFilter)\($0))" } ?? objectClassFilter
        let result: OpaquePointer = try LDAPError.validate { resultPtr in
            [LDAP_ALL_USER_ATTRIBUTES, LDAP_ALL_OPERATIONAL_ATTRIBUTES].withMutableArrayOfCStrings {
                $0.withUnsafeMutableBufferPointer {
                    ldap_search_ext_s(handle, base, LDAP_SCOPE_CHILDREN, actualFilter, $0.baseAddress, 0, nil, nil, nil, .max, &resultPtr)
                }
            }
        }
        func readAttributes(entryPtr: OpaquePointer) throws -> [AttributeKey: Any] {
            func readValues(attributeKey: UnsafePointer<CChar>) throws -> Any? {
                guard let valuesPtr = ldap_get_values_len(handle, entryPtr, attributeKey) else { return nil }
                defer { free(valuesPtr) }
                let values = UnsafeMutableBufferPointer(start: valuesPtr, count: numericCast(ldap_count_values_len(valuesPtr))).compactMap {
                    $0.map { String(cString: $0.pointee.bv_val) }
                }
                if values.isEmpty { return Optional<Any>.none as Any }
                return values.count == 1 ? values[0] : values
            }
            var attrPtr: OpaquePointer?
            guard let firstAttrKey = ldap_first_attribute(handle, entryPtr, &attrPtr) else { return [:] }
            var attributes: [AttributeKey: Any] = [:]
            attributes[.init(rawValue: String(cString: firstAttrKey))] = try readValues(attributeKey: firstAttrKey)
            while let attributeKey = ldap_next_attribute(handle, entryPtr, attrPtr) {
                let key = AttributeKey(rawValue: String(cString: attributeKey))
                attributes[key] = try readValues(attributeKey: attributeKey)
            }
            return attributes
        }
        var resultObjects = Array<LDAPObject<T>>()
        if case let count = ldap_count_entries(handle, result), count >= 0 {
            resultObjects.reserveCapacity(numericCast(count))
        }
        var entryPtr_ = ldap_first_entry(handle, result)
        while let entryPtr = entryPtr_ {
            try resultObjects.append(.init(storage: readAttributes(entryPtr: entryPtr)))
            entryPtr_ = ldap_next_entry(handle, entryPtr)
        }
        return resultObjects
    }
}

fileprivate extension Collection where Element == String {
    func withMutableArrayOfCStrings<R>(_ body: (inout [UnsafeMutablePointer<CChar>?]) throws -> R) rethrows -> R {
        var cStrings = map { strdup($0) } + CollectionOfOne(nil)
        defer { cStrings.forEach { free($0) } }
        return try body(&cStrings)
    }
}
