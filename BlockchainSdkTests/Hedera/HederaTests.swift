//
//  HederaTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Fedorov on 18.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk
import enum WalletCore.Curve
import class WalletCore.PrivateKey
import struct Hedera.AccountId

@testable import BlockchainSdk

final class HederaTests: XCTestCase {
    /// SAUCE testnet token https://hashscan.io/testnet/token/0.0.1183558
    private let token = Token(name: "SAUCE", symbol: "SAUCE", contractAddress: "0.0.1183558", decimalCount: 6)
    private var blockchain: Blockchain!
    private var sizeTester: TransactionSizeTesterUtility!

    override func tearDown() {
        blockchain = nil
        sizeTester = nil
    }

    func testSigningCoinTransactionECDSA() throws {
        setUp(curve: .secp256k1)

        // MARK: - Public & private keys

        // ECDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x3030020100300706052b8104000a04220420e507077d8d5bab32debcbbc651fc4ca74660523976502beabee15a1662d77ed1")

        // Hedera ECDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/f65ab2a4cf5bb026fc47fcf8955e81c2b82a6ff3/packages/cryptography/src/EcdsaPrivateKey.js#L7
        let hederaDerPrefixPrivate = Data(hexString: "0x3030020100300706052b8104000a04220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))
        let publicKeyRaw = try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).data

        // MARK: - Building & compiling transaction

        let sourceAddress = "0.0.3573746"
        let destinationAddress = "0.0.1654"

        let value = try XCTUnwrap(Decimal(string: "7.2"))
        let amount = Amount(with: blockchain, type: .coin, value: value)

        let feeValue = try XCTUnwrap(Decimal(string: "1.0"))
        let feeAmount = Amount(with: blockchain, value: feeValue)
        let fee = Fee(feeAmount)

        let validStartDate = UnixTimestamp(seconds: 1708443033, nanoseconds: 758181256)
        let params = HederaTransactionParams(memo: "reference ECDSA tx")

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: destinationAddress,
            params: params
        )

        let transactionBuilder = HederaTransactionBuilder(
            publicKey: publicKeyRaw,
            curve: blockchain.curve,
            isTestnet: blockchain.isTestnet
        )

        let compiledTransaction = try transactionBuilder.buildTransferTransactionForSign(
            transaction: transaction,
            validStartDate: validStartDate,
            nodeAccountIds: [6]
        )

        // MARK: - Signing transaction

        let curve = try Curve(blockchain: blockchain)
        let hashesToSign = try compiledTransaction.hashesToSign()

        hashesToSign.forEach { sizeTester.testTxSize($0) }

        let signatures = try hashesToSign.map { digest in
            let signature = try XCTUnwrap(privateKey.sign(digest: digest, curve: curve))
            return try Secp256k1Signature(with: signature).normalize()
        }

        let signedTransaction = try transactionBuilder.buildForSend(transaction: compiledTransaction, signatures: signatures)

        // MARK: - Validating results

        let encodedTransaction = try signedTransaction.toBytes().hexString

        // Hedera coin transfer transaction (testnet):
        // https://hashscan.io/testnet/transaction/1708443042.503872003
        //
        // Made using Hedera™ Swift SDK 0.26.0, https://github.com/hashgraph/hedera-sdk-swift
        let expectedEncodedTransaction = """
        0AC6012AC3010A580A150A0C08998BD3AE061088DBC3E902120518F28FDA01120218061880C2D72F22020878321272656665\
        72656E6365204543445341207478721E0A1C0A0D0A0518F28FDA0110FFCFD2AE050A0B0A0318F60C1080D0D2AE0512670A65\
        0A2103E44158C7CFF81F6A0F01E9D27D8FF9A734EF0F83933499A13BB61FCA447AC4E63240D82DEBE31EF6795B015F79A0C8\
        0307CFD8B057BE31A500EDCFE3EB29D2E1A3903EF2F31788E8A6D1B91A690A617E7D85786D19CBEA2EB4189E79BA4F9827E3A4
        """

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    func testSigningCoinTransactionEdDSA() throws {
        setUp(curve: .ed25519_slip0010)

        // MARK: - Public & private keys

        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))
        let publicKeyRaw = try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).data

        // MARK: - Building & compiling transaction

        let sourceAddress = "0.0.3551642"
        let destinationAddress = "0.0.1654"

        let value = try XCTUnwrap(Decimal(string: "3.5"))
        let amount = Amount(with: blockchain, type: .coin, value: value)

        let feeValue = try XCTUnwrap(Decimal(string: "1.0"))
        let feeAmount = Amount(with: blockchain, value: feeValue)
        let fee = Fee(feeAmount)

        let validStartDate = UnixTimestamp(seconds: 1708438431, nanoseconds: 140337611)
        let params = HederaTransactionParams(memo: "reference EdDSA tx")

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: destinationAddress,
            params: params
        )

        let transactionBuilder = HederaTransactionBuilder(
            publicKey: publicKeyRaw,
            curve: blockchain.curve,
            isTestnet: blockchain.isTestnet
        )

        let compiledTransaction = try transactionBuilder.buildTransferTransactionForSign(
            transaction: transaction,
            validStartDate: validStartDate,
            nodeAccountIds: [6]
        )

        // MARK: - Signing transaction

        let curve = try Curve(blockchain: blockchain)
        let hashesToSign = try compiledTransaction.hashesToSign()

        hashesToSign.forEach { sizeTester.testTxSize($0) }

        let signatures = try hashesToSign.map { digest in
            return try XCTUnwrap(privateKey.sign(digest: digest, curve: curve))
        }

        let signedTransaction = try transactionBuilder.buildForSend(transaction: compiledTransaction, signatures: signatures)

        // MARK: - Validating results

        let encodedTransaction = try signedTransaction.toBytes().hexString

        // Hedera coin transfer transaction (testnet):
        // https://hashscan.io/testnet/transaction/1708438449.753341411
        //
        // Made using Hedera™ Swift SDK 0.26.0, https://github.com/hashgraph/hedera-sdk-swift
        let expectedEncodedTransaction = """
        0AC4012AC1010A570A140A0B089FE7D2AE0610CBC3F5421205189AE3D801120218061880C2D72F2202087832127265666572\
        656E6365204564445341207478721E0A1C0A0D0A05189AE3D80110FFCDE4CD020A0B0A0318F60C1080CEE4CD0212660A640A\
        20236B71BED98B98EACDEA958B312750E91DCCBE1290CE005F2A245243E3D6182C1A4069C561556EEC9879FF7ACD8458EA44\
        8E1727731F44F08958D24FF1E19877062355C9D5707734B6AD9288C1D774A2B249F1E7D49220C3559323F2A3A29DE64609
        """

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    func testSigningTokenTransactionECDSA() throws {
        setUp(curve: .secp256k1)

        // MARK: - Public & private keys

        // ECDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x3030020100300706052b8104000a04220420e507077d8d5bab32debcbbc651fc4ca74660523976502beabee15a1662d77ed1")

        // Hedera ECDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/f65ab2a4cf5bb026fc47fcf8955e81c2b82a6ff3/packages/cryptography/src/EcdsaPrivateKey.js#L7
        let hederaDerPrefixPrivate = Data(hexString: "0x3030020100300706052b8104000a04220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))
        let publicKeyRaw = try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).data

        // MARK: - Building & compiling transaction

        let sourceAddress = "0.0.3573746"
        let destinationAddress = "0.0.1654"

        let value = try XCTUnwrap(Decimal(string: "32.43"))
        let amount = Amount(with: blockchain, type: .token(value: token), value: value)

        let feeValue = try XCTUnwrap(Decimal(string: "1.0"))
        let feeAmount = Amount(with: blockchain, value: feeValue)
        let fee = Fee(feeAmount)

        let validStartDate = UnixTimestamp(seconds: 1714012118, nanoseconds: 578760253)
        let params = HederaTransactionParams(memo: "SAUCE token reference ECDSA tx")

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: destinationAddress,
            params: params
        )

        let transactionBuilder = HederaTransactionBuilder(
            publicKey: publicKeyRaw,
            curve: blockchain.curve,
            isTestnet: blockchain.isTestnet
        )

        let compiledTransaction = try transactionBuilder.buildTransferTransactionForSign(
            transaction: transaction,
            validStartDate: validStartDate,
            nodeAccountIds: [7]
        )

        // MARK: - Signing transaction

        let curve = try Curve(blockchain: blockchain)
        let hashesToSign = try compiledTransaction.hashesToSign()

        hashesToSign.forEach { sizeTester.testTxSize($0) }

        let signatures = try hashesToSign.map { digest in
            let signature = try XCTUnwrap(privateKey.sign(digest: digest, curve: curve))
            return try Secp256k1Signature(with: signature).normalize()
        }

        let signedTransaction = try transactionBuilder.buildForSend(transaction: compiledTransaction, signatures: signatures)

        // MARK: - Validating results

        let encodedTransaction = try signedTransaction.toBytes().hexString

        // Hedera SAUCE token transfer transaction (testnet):
        // https://hashscan.io/testnet/transaction/1714012120.446674433
        //
        // Made using Hedera™ Swift SDK 0.26.0, https://github.com/hashgraph/hedera-sdk-swift
        let expectedEncodedTransaction = """
        0AD8012AD5010A6A0A150A0C08D6FFA6B10610BDDCFC9302120518F28FDA01120218071880C2D72F22020878321E53415543\
        4520746F6B656E207265666572656E636520454344534120747872240A0012200A0418C69E48120C0A0518F28FDA0110DFDE\
        F61E120A0A0318F60C10E0DEF61E12670A650A2103E44158C7CFF81F6A0F01E9D27D8FF9A734EF0F83933499A13BB61FCA44\
        7AC4E632408B39589B568197C723ADAC7C14C24A9E72EE53891CDBEDFA420B2F86BB6DE6E54B97FFE9EC6FB56F49D8CABD93\
        13FBFE621DA3440061BF60F1DE055914E66288
        """

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    func testSigningTokenTransactionEdDSA() throws {
        setUp(curve: .ed25519_slip0010)

        // MARK: - Public & private keys

        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))
        let publicKeyRaw = try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).data

        // MARK: - Building & compiling transaction

        let sourceAddress = "0.0.3551642"
        let destinationAddress = "0.0.1654"

        let value = try XCTUnwrap(Decimal(string: "15.82"))
        let amount = Amount(with: blockchain, type: .token(value: token), value: value)

        let feeValue = try XCTUnwrap(Decimal(string: "1.0"))
        let feeAmount = Amount(with: blockchain, value: feeValue)
        let fee = Fee(feeAmount)

        let validStartDate = UnixTimestamp(seconds: 1714034135, nanoseconds: 463758056)
        let params = HederaTransactionParams(memo: "SAUCE token reference EdDSA tx")

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: destinationAddress,
            params: params
        )

        let transactionBuilder = HederaTransactionBuilder(
            publicKey: publicKeyRaw,
            curve: blockchain.curve,
            isTestnet: blockchain.isTestnet
        )

        let compiledTransaction = try transactionBuilder.buildTransferTransactionForSign(
            transaction: transaction,
            validStartDate: validStartDate,
            nodeAccountIds: [8]
        )

        // MARK: - Signing transaction

        let curve = try Curve(blockchain: blockchain)
        let hashesToSign = try compiledTransaction.hashesToSign()

        hashesToSign.forEach { sizeTester.testTxSize($0) }

        let signatures = try hashesToSign.map { digest in
            return try XCTUnwrap(privateKey.sign(digest: digest, curve: curve))
        }

        let signedTransaction = try transactionBuilder.buildForSend(transaction: compiledTransaction, signatures: signatures)

        // MARK: - Validating results

        let encodedTransaction = try signedTransaction.toBytes().hexString

        // Hedera SAUCE token transfer transaction (testnet):
        // https://hashscan.io/testnet/transaction/1714034136.316923003
        //
        // Made using Hedera™ Swift SDK 0.26.0, https://github.com/hashgraph/hedera-sdk-swift
        let expectedEncodedTransaction = """
        0AD7012AD4010A6A0A150A0C08D7ABA8B10610E8C591DD011205189AE3D801120218081880C2D72F22020878321E53415543\
        4520746F6B656E207265666572656E636520456444534120747872240A0012200A0418C69E48120C0A05189AE3D80110BF93\
        8B0F120A0A0318F60C10C0938B0F12660A640A20236B71BED98B98EACDEA958B312750E91DCCBE1290CE005F2A245243E3D\
        6182C1A4006A0CCA70E40D72B0B2F58F402EC16BE4716DC2032C9737EDD7CAA135653866AA0231461725FE661F0E562CFAE\
        8A748B9CA71BD92005A84DB4E7DA3CA789FD0A
        """

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    private func setUp(curve: EllipticCurve) {
        blockchain = .hedera(curve: curve, testnet: true)
        sizeTester = TransactionSizeTesterUtility()
    }
}
