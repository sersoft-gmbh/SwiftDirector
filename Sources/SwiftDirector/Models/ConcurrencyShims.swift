#if compiler(>=5.5) && canImport(_Concurrency)
public typealias _SwiftDirectorSendable = Sendable
#else
public typealias _SwiftDirectorSendable = Any
#endif
