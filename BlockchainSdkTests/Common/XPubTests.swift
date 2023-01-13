//
//  XPubTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemSdk
@testable import BlockchainSdk

class XPubTests: XCTestCase {
    func testRoundTrip() throws {
        let key = try XpubKey(
            depth: 3,
            parentFingerprint: Data(hexString: "0x00000000"),
            childNumber: 2147483648,
            chainCode:  Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"),
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        )

        let xpubString = try key.serialize(for: .mainnet)
        let deserializedKey = try XpubKey(from: xpubString, version: .mainnet)

        XCTAssertEqual(key, deserializedKey)
    }

    func testInitWithParentKey() throws {
        let parentKey = Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        let parentFingerprint = parentKey.sha256Ripemd160.prefix(4)

        let key = try XpubKey(
            depth: 1,
            parentKey: parentKey,
            childNumber: 0,
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"),
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        )

        XCTAssertEqual(key.parentFingerprint, parentFingerprint)
    }

    func testInitMaster() throws {
        let key = try XpubKey(
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"),
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        )

        XCTAssertEqual(key.depth, 0)
        XCTAssertEqual(key.parentFingerprint, Data(hexString: "0x00000000"))
        XCTAssertEqual(key.childNumber, 0)
    }

    func testInitWithEdKey() {
        XCTAssertThrowsError(try XpubKey(chainCode: Data(hexString: "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea"),
                                         publicKey: Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")))
    }

    func testSerialization() throws {
        let mKeyString = "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
        let mXpubKey = try XpubKey(from: mKeyString, version: .mainnet)

        let key = try XpubKey(
            depth: 1,
            parentKey: mXpubKey.publicKey,
            childNumber: 2147483648,
            chainCode: Data(hexString: "47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141"),
            publicKey: Data(hexString: "035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56")
        )

        let serialized = try key.serialize(for: .mainnet)
        XCTAssertEqual(serialized, "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw")
    }

    func testBadKeys() {
        XCTAssertThrowsError(try XpubKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Q5JXayek4PRsn35jii4veMimro1xefsM58PgBMrvdYre8QyULY", version: .mainnet))

        XCTAssertThrowsError(try XpubKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHPmHJiEDXkTiJTVV9rHEBUem2mwVbbNfvT2MTcAqj3nesx8uBf9", version:.mainnet))

        XCTAssertThrowsError(try XpubKey(from: "xpub661MyMwAuDcm6CRQ5N4qiHKrJ39Xe1R1NyfouMKTTWcguwVcfrZJaNvhpebzGerh7gucBvzEQWRugZDuDXjNDRmXzSZe4c7mnTK97pTvGS8", version: .mainnet))

        XCTAssertThrowsError(try XpubKey(from: "xpub661no6RGEX3uJkY4bNnPcw4URcQTrSibUZ4NqJEw5eBkv7ovTwgiT91XX27VbEXGENhYRCf7hyEbWrR3FewATdCEebj6znwMfQkhRYHRLpJ", version: .mainnet))

        XCTAssertThrowsError(try XpubKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6N8ZMMXctdiCjxTNq964yKkwrkBJJwpzZS4HS2fxvyYUA4q2Xe4", version: .mainnet))

        XCTAssertThrowsError(try XpubKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Txnt3siSujt9RCVYsx4qHZGc62TG4McvMGcAUjeuwZdduYEvFn", version: .mainnet))
    }
}
