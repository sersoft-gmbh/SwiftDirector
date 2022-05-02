# SwiftDirector

[![GitHub release](https://img.shields.io/github/release/sersoft-gmbh/SwiftDirector.svg?style=flat)](https://github.com/sersoft-gmbh/SwiftDirector/releases/latest)
![Tests](https://github.com/sersoft-gmbh/SwiftDirector/workflows/Tests/badge.svg)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/881ad22124074683a8e001bb1864ca71)](https://www.codacy.com/gh/sersoft-gmbh/SwiftDirector?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=sersoft-gmbh/SwiftDirector&amp;utm_campaign=Badge_Grade)
[![codecov](https://codecov.io/gh/sersoft-gmbh/SwiftDirector/branch/master/graph/badge.svg)](https://codecov.io/gh/sersoft-gmbh/SwiftDirector)
[![Docs](https://img.shields.io/badge/-documentation-informational)](https://sersoft-gmbh.github.io/SwiftDirector/documentation/swiftdirector)

A Swift interface for (Open)LDAP.

## Installation

Add the following dependency to your `Package.swift`:
```swift
.package(url: "https://github.com/sersoft-gmbh/SwiftDirector.git", from: "1.0.0"),
```

## Usage

### LDAPServer

The first thing you need is an `LDAPServer`. There are two convenience static methods to get one:
```swift
// This uses the ldap:// scheme and the default LDAP port
let server = LDAPServer.ldap(host: "ldap.mydomain.com")
/* OR */
// This uses the ldaps:// scheme and the default LDAPS port
let server = LDAPServer.ldaps(host: "ldaps.mydomain.com")
```

Both methods optionally take a `port` parameter if you require a non-default port. If you need different schemes, there is the `LDAPServer(scheme:host:port)` initializer with which you can create a fully customized `LDAPServer`.

### LDAPConnection

#### Binding and unbinding
Once you have a server, you need a connection. `LDAPServer` has a method named `openConnection` that will do exactly this for you:
```swift
let connection = try server.openConnection()
```

With the connection you can then perform LDAP operations like e.g. binding:
```swift
try connection.bind(dn: "cn=admin,dc=mydomain,dc=com", credentials: "supersecret")
```

The connection will automatically try to unbind itself once it's deallocated, but you can also explicitly do so:
```swift
try connection.unbind()
```
Note, however, that a connection cannot be re-bound once unbound. An unbound connection is invalid and a new connection has to be obtained from the server. Any operation on an unbound connection will fail (and assert in debug builds).

#### Duplicating

A connection can be duplicated. A normal duplicated connection depends on its original connection. This means that if a connection is invalidated (unbound), all its siblings will be invalid as well.
Duplicated connections will destroy themselves when deallocated - leaving the original connection valid. There is also an explicit `close` function which will destroy duplicated connections and unbind primary connections.

Note that a duplicat of an `LDAPConnection` retains its original connection to make sure the original connection doesn't unbind itself during deallocation, thus rendering the duplicate invalid as well.

#### Searching

Ultimately, a connection can be used to search the directory. The `search(for:inBase:filteredBy:)` method is the way to go for that.
The first parameter is the type of object class you want to search for. It defines what kind of object will be returned. If you want any object, pass `AnyObjectClass` in there. Note, however, that you won't be able to extract much information from the resulting objects (see below for more information).
The `base` paremeter defines the base DN to use for the search.
With the optional `filter`, wich defaults to `nil`, you can further filter the results (in addition to the object class). Simply pass in a valid LDAP filter.

```swift
let results = try connection.search(for: ShadowAccount.self, inBase: "dc=mydomain,dc=com")
// `results`: Array<LDAPObject<ShadowAccount>>
for result in results {
    print(result.userID) // prints usernames of accounts
}
```

### Object Classes

Object classes describe the attributes that are available on an object. In SwiftDirector, object classes are represented as protocols and (empty) structs which are used in combination with the `@dynamicMemberLookup` features of Swift to allow you to easily access information on an `LDAPObject` (see below).

All object classes have to inherit from the `ObjectClassProtocol`. However, since usually all object classes actually inherit from the top object class, it's semantically more correct to let your object classes also inhert from `TopObjectClassProtocol`.

There is also a `AnyObjectClass` struct, that will allow searching for any object class.

SwiftDirector currently makes no effort to deliver a conclusive list of object class implementations. The list of implementations that SwiftDirector ships will grow over time, though. It's easy, however, to implement your own object class (or one that is missing). You simply create a protocol that is named after your object class and has the `Protocol` suffix. The protocol itself simply defines the inheritance from other object classes but defines no requirements. In a protocol extension you then define the available attributes of this object class. Finally, you also add a struct that is named after your object class that can then be used for searching.
Let's take a look at how a `MySpecialPerson` object class (inheriting from `InetOrgPerson`) might be implemented:

```swift
public protocol MySpecialPersonProtocol: InetOrgPersonProtocol {}

extension MySpecialPersonProtocol {
    // Only make the attribute's type non-optional if LDAP requires the precense of the attribute!
    public var myNameAttribute: Attribute<String> { .init(key: "myName") }

    // An optional attribute of type Int.
    public var myOptionalSize: Attribute<Int?> { .init(key: "mySize") }

    // Collections can always be declared non-optional. If the attribute is missing, the value will be an empty collection.
    public var myList: Attribute<Array<Int>> { .init(key: "myList") }
}

public struct MySpecialPerson: MySpecialPersonProtocol {
    // The oid of the object class.
    public static var oid: String { "1.2.3.4.5" }
    // The name as it occurs in e.g the objectClass attribute of an object
    public static var name: String { "mySpecialPerson" }

    // An empty initializer allowing SwiftDirector to create an instance of your object class definition.
    public init() {}
}
```

### LDAPObject

An `LDAPObject` represents a concrete object retrieved from an LDAP directory. It's a generic struct whose generic parameter has to be an object class. It gives access to the object class' attributes which are exposed as simple properties thanks to the power of `@dynamicMemberLookup`:

```swift
let object: LDAPObject<ShadowAccount> // retrieved from a search
let username = object.userID // Extract the username
```

The `LDAPObject` can also deal with the fact that in LDAP you can have an object that has multiple object classes ("multiple inheritance"). While you can't directly access attributes of a simbling object class, there are methods that allow safe casting to different object classes:

```swift
let object: LDAPObject<ShadowAccount> // retrieved from a search
if let inetOrgPerson = object.cast(to: InetOrgPerson.self) {
    // Here you have access to attributes of the `InetOrgPerson` object class
    print(inetOrgPerson.mail ?? "No email address available")
}
```

You can also simply check if the cast would succeed using `canCast(to:)`. And if for some reason you are **absolutely sure** that a given object can be casted to another object class, there is also `forceCast(to:)`. The latter should be treated similar to `try!` in Swift and only be used if absolutely necessary.

Furthermore, `LDAPObject` allows checking for the availability of attributes:

```swift
let object: LDAPObject<ShadowAccount> // retrieved from a search
object.hasAttribute(\.authPassword) // Returns whether or not `authPassword` is available.
```

Finally, `LDAPObject` uses the identifying attribute specified by the object class to conform to `Equatable`, `Hashable` and `Identifiable`.

## Possible Features

While not yet integrated, the following features might provide added value and could make it into SwiftDirector in the future:

-   Type safe LDAP filters.
-   Write operations.
-   More object class implementations.
-   More bind methods.

## Documentation

The API is documented using header doc. If you prefer to view the documentation as a webpage, there is an [online version](https://sersoft-gmbh.github.io/SwiftDirector/documentation/swiftdirector) available for you.

## Contributing

If you find a bug / like to see a new feature in SwiftDirector there are a few ways of helping out:

-   If you can fix the bug / implement the feature yourself please do and open a PR.
-   If you know how to code (which you probably do), please add a (failing) test and open a PR. We'll try to get your test green ASAP.
-   If you can do neither, then open an issue. While this might be the easiest way, it will likely take the longest for the bug to be fixed / feature to be implemented.

## License

See [LICENSE](./LICENSE) file.

