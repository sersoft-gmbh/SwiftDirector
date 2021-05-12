// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
#if !os(Linux)
import Foundation
#endif

fileprivate extension Target {
    static func cldap() -> Target {
        #if os(Linux)
        return systemLibrary(
            name: "CLDAP",
            path: "Sources/CLDAPLinux",
            providers: [
                .apt(["libldap2-dev"]),
                .brew(["openldap"]),
        ])
        #else
        #if arch(arm)
        let openldapPath = "/usr/local/opt/openldap"
        #else
        let openldapPath = "/opt/homebrew/opt/openldap"
        #endif
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: openldapPath, isDirectory: &isDir) || !isDir.boolValue {
            print("'\(openldapPath)' is missing! Builds will most likely fail. Please install 'openldap' with e.g. 'brew install openldap'")
        }
        return target(
            name: "CLDAP",
            path: "Sources/CLDAPMac",
            cSettings: [
//                .headerSearchPath("\(openldapPath)/include", .when(platforms: [.iOS, .tvOS, .watchOS, .macOS])),
                .unsafeFlags(["-I\(openldapPath)/include"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS])),
            ],
            linkerSettings: [
                .unsafeFlags(["-L\(openldapPath)/lib"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS])),
                .linkedLibrary("ldap"),
            ])
        #endif
    }
}

let package = Package(
    name: "SwiftDirector",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftDirector",
            targets: ["SwiftDirector"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .cldap(),
        .target(
            name: "SwiftDirector",
            dependencies: ["CLDAP"]
        ),
        .testTarget(
            name: "SwiftDirectorTests",
            dependencies: ["CLDAP", "SwiftDirector"]),
    ]
)
