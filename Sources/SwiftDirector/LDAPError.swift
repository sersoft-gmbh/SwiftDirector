import CLDAP

/// A typealias for the error codes used in LDAP.
typealias LDAPErrno = CInt

/// The error type representing errors occurring during LDAP operations.
public struct LDAPError: Error, Equatable, CustomStringConvertible {
    private enum Kind: Equatable {
        case ldap(LDAPErrno)
        case unknown
    }
    private let kind: Kind

    var ldapErrno: LDAPErrno? {
        guard case .ldap(let errno) = kind else { return nil }
        return errno
    }

    public var description: String {
        switch kind {
        case .ldap(let errno): return "[\(Self.self)] \(String(cString: ldap_err2string(errno)))"
        case .unknown: return "[\(Self.self)] An unknown error occurred!"
        }
    }

    private init(kind: Kind) {
        self.kind = kind
    }

    init(nonZeroErrno: LDAPErrno) {
        precondition(nonZeroErrno != 0)
        self.init(kind: .ldap(nonZeroErrno))
    }

    init?(errno: LDAPErrno) {
        guard errno != 0 else { return nil }
        self.init(kind: .ldap(errno))
    }

    /// An unknown error that does not correspond to any LDAP error.
    /// Usually occurs if ldap returned a success status code but not the necessary results.
    public static var unknown: LDAPError { .init(kind: .unknown) }
}

// MARK: - Execution Helpers
extension LDAPError {
    private static func _validateVoid(work: () -> LDAPErrno, beforeThrow: () -> ()) throws {
        if let error = LDAPError(errno: work()) {
            beforeThrow()
            throw error
        }
    }

    static func validateVoid(work: () -> LDAPErrno) throws {
        try _validateVoid(work: work, beforeThrow: {})
    }

    static func validate<T>(freeingWith free: ((T?) -> ())? = nil, work: (inout T?) -> LDAPErrno) throws -> T {
        var result: T?
        try _validateVoid(work: { work(&result) }, beforeThrow: { free?(result) })
        guard let unwrappedResult = result else { throw unknown }
        return unwrappedResult
    }
}
