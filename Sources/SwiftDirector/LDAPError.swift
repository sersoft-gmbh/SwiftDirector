import CLDAP

typealias LDAPErrno = CInt

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
        case .ldap(let errno): return String(cString: ldap_err2string(errno))
        case .unknown: return "An unknown error occurred!"
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
        self.init(nonZeroErrno: errno)
    }

    public static var unknown: LDAPError { .init(kind: .unknown) }
}

extension LDAPError {
    static func validateVoid(work: () throws -> LDAPErrno) throws {
        if let error = try LDAPError(errno: work()) {
            throw error
        }
    }

    static func validate<T>(work: (inout T?) throws -> LDAPErrno) throws -> T {
        var result: T?
        try validateVoid { try work(&result) }
        guard let unwrappedResult = result else { throw unknown }
        return unwrappedResult
    }
}
