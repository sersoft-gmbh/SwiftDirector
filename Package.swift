// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target {
    static var cldap: Target {
        #if os(Linux)
        return systemLibrary(
            name: "CLDAP",
            path: "Sources/CLDAPLinux",
            providers: [
                .apt(["libldap2-dev"]),
                .brew(["openldap"]),
        ])
        #else
        return target(
            name: "CLDAP",
            path: "Sources/CLDAPMac",
            cSettings: [
                .unsafeFlags(["-I/usr/local/opt/openldap/include"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS]))
            ],
            linkerSettings: [
                .unsafeFlags(["-L/usr/local/opt/openldap/lib"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS])),
                .linkedLibrary("ldap")
            ])
        #endif
    }
}

let package = Package(
    name: "SwiftDirector",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftDirector",
            targets: ["SwiftDirector"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .cldap,
        .target(
            name: "SwiftDirector",
            dependencies: [
                "CLDAP",
            ]
        ),
        .testTarget(
            name: "SwiftDirectorTests",
            dependencies: ["CLDAP", "SwiftDirector"]),
    ]
)
