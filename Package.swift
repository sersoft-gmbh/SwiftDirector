// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

fileprivate extension Target {
    static func cLDAP() -> Target {
#if os(Linux)
        return systemLibrary(
            name: "CLDAP",
            path: "Sources/CLDAPLinux",
            providers: [
                .apt(["libldap2-dev"]),
                .brew(["openldap"]),
            ])
#else
#if arch(arm64) || arch(arm)
        let openldapPath = "/opt/homebrew/opt/openldap"
#else
        let openldapPath = "/usr/local/opt/openldap"
#endif
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: openldapPath, isDirectory: &isDir) || !isDir.boolValue {
            print("'\(openldapPath)' is missing! Builds will most likely fail. Please install 'openldap' with e.g. 'brew install openldap'")
        }
        return target(
            name: "CLDAP",
            path: "Sources/CLDAPMac",
            cSettings: [
//                .headerSearchPath("\(openldapPath)/include", .when(platforms: [.iOS, .tvOS, .watchOS, .macOS, .macCatalyst])),
                .unsafeFlags(["-I\(openldapPath)/include"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS, .macCatalyst])),
            ],
            linkerSettings: [
                .unsafeFlags(["-L\(openldapPath)/lib"], .when(platforms: [.iOS, .tvOS, .watchOS, .macOS, .macCatalyst])),
                .linkedLibrary("ldap"),
            ])
#endif
    }
}

let swiftSettings: Array<SwiftSetting> = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
//    .enableExperimentalFeature("AccessLevelOnImport"),
//    .enableExperimentalFeature("VariadicGenerics"),
//    .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),
]

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .cLDAP(),
        .target(
            name: "SwiftDirector",
            dependencies: ["CLDAP"],
            resources: [
                .process("Documentation.docc"),
            ],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "SwiftDirectorTests",
            dependencies: [
                "CLDAP",
                "SwiftDirector",
            ],
            swiftSettings: swiftSettings),
    ]
)
