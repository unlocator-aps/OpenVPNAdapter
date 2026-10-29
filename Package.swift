// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "OpenVPNAdapter",
    platforms: [
        .iOS("9.0"),
        .macOS("10.11"),
        .tvOS("17.0"),
    ],
    products: [
        .library(name: "OpenVPNAdapter", type: .static, targets: ["OpenVPNAdapter"]),
    ],
    targets: [
        .target(
            name: "OpenVPNAdapter",
            dependencies: [
                .target(name: "mbedTLS"),
                .target(name: "OpenVPNClient")
            ],
            sources: ["library"],
            cxxSettings: [
                .headerSearchPath("../ASIO/asio/include"),
                .headerSearchPath("../OpenVPN3"),
                .define("USE_ASIO")
            ],
            linkerSettings: [
                // Link the packet-tunnel bridge and reachability APIs on all supported platforms.
                // Adapter bridge: Sources/OpenVPNAdapter/library/OpenVPNAdapterImpl.mm.
                .linkedFramework("NetworkExtension"),
                .linkedFramework("SystemConfiguration"),
            ]
        ),
        .target(
            name: "LZ4",
            sources: ["lib"],
            cSettings: [
                .define("XXH_NAMESPACE", to: "LZ4_")
            ]
        ),
        .target(
            name: "mbedTLS",
            sources: ["library"],
            cSettings: [
                .define("MBEDTLS_MD4_C"),
                .define("MBEDTLS_RELAXED_X509_DATE"),
                .define("_FILE_OFFSET_BITS", to: "64"),
            ]
        ),
        .target(
            name: "OpenVPNClient",
            dependencies: [
                .target(name: "LZ4"),
                .target(name: "mbedTLS")
            ],
            sources: ["library"],
            cxxSettings: [
                .headerSearchPath("../ASIO/asio/include"),
                .headerSearchPath("../OpenVPN3"),
                .define("USE_ASIO"),
                .define("USE_ASIO_THREADLOCAL"),
                .define("ASIO_STANDALONE"),
                .define("ASIO_NO_DEPRECATED"),
                .define("ASIO_HAS_STD_STRING_VIEW"),
                .define("USE_MBEDTLS"),
                .define("HAVE_LZ4"),
                .define("OPENVPN_FORCE_TUN_NULL"),
                .define("USE_TUN_BUILDER")
            ],
            linkerSettings: [
                // Reuse the iOS hardware ID helper on tvOS because UIDevice is available there.
                // Link UIKit only on mobile platforms; macOS uses its existing hardware ID path.
                // Engine helper: Sources/OpenVPN3/openvpn/netconf/hwaddr.hpp.
                .linkedFramework(
                    "UIKit", .when(platforms: [.iOS, .tvOS])
                ),
            ]
        )
    ],
    cxxLanguageStandard: .gnucxx14
)
