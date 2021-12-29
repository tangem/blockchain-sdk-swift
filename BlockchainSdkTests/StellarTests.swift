//
//  StellarTests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 04/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import XCTest
import stellarsdk
import Combine

class StellarTests: XCTestCase {

    private let blockchain = Blockchain.stellar(testnet: false)

    private lazy var addressService = blockchain.getAddressService()
    private var bag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
//        continueAfterFailure = false
        bag = []
    }
    
    func testAddress() {
        let walletPubkey = Data(hex: "EC5387D8B38BD9EF80BDBC78D0D7E1C53F08E269436C99D5B3C2DF4B2CE73012")
        let expectedAddress = "GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"

        XCTAssertEqual(addressService.makeAddress(from: walletPubkey), expectedAddress)
    }

    func testValidateCorrectAddress() {
        XCTAssertTrue(addressService.validate("GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"))
    }


    func testCorrectCoinTransaction() {
        let walletPubkey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
        let signature = Data(hex: "EA1908DD1B2B0937758E5EFFF18DB583E41DD47199F575C2D83B354E29BF439C850DC728B9D0B166F6F7ACD160041EE3332DAD04DD08904CB0D2292C1A9FB802")

        let sendValue = Decimal(0.1)
        let feeValue = Decimal(0.00001)
        let destinationAddress = "GBPMXXLHHPCOO4YOWGS4BWSVMLELZ355DVQ6JCGZX3H4HO3LH2SUETUW"

        let walletAddress = addressService.makeAddress(from: walletPubkey)

        let txBuilder = StellarTransactionBuilder(stellarSdk: StellarSDK(withHorizonUrl: "https://horizon.stellar.org"), walletPublicKey: walletPubkey, isTestnet: false)
        txBuilder.sequence = 139655650517975046
        txBuilder.specificTxTime = 1614848128.2697558

        let amountToSend = Amount(with: blockchain, type: .coin, value: sendValue)
        let feeAmount = Amount(with: blockchain, type: .coin, value: feeValue)
        let tx = Transaction(amount: amountToSend, fee: feeAmount, sourceAddress: walletAddress, destinationAddress: destinationAddress, changeAddress: walletAddress)

        let expectedHashToSign = Data(hex: "96994C3FA90044DD7991F9A4DD4CFBFDD6D2B684F60439DE49E66D5026A84C0A")
        let expectedSignedTx = "AAAAAgAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAGQB8CgTAAAABwAAAAEAAAAAYECgRAAAAABgQKC8AAAAAQAAAAAAAAABAAAAAQAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAAEAAAAAXsvdZzvE53MOsaXA2lViyLzvvR1h5IjZvs/Du2s+pUIAAAAAAAAAAAAPQkAAAAAAAAAAAbuKrD0AAABA6hkI3RsrCTd1jl7/8Y21g+Qd1HGZ9XXC2Ds1Tim/Q5yFDccoudCxZvb3rNFgBB7jMy2tBN0IkEyw0iksGp+4Ag=="

        let expectations = expectation(description: "All values received")

        txBuilder.buildForSign(transaction: tx)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Failed to build tx. Reason: \(error.localizedDescription)")
                }
            }, receiveValue: { (hash, txData) in
                XCTAssertEqual(hash, expectedHashToSign)

                guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
                    XCTFail("Failed to build tx for send")
                    return
                }

                XCTAssertEqual(signedTx, expectedSignedTx)

                expectations.fulfill()
                return
            })
            .store(in: &bag)


        waitForExpectations(timeout: 1, handler: nil)
    }

//        @Test
//        fun buildCorrectTokenTransaction() {
//            // arrange
//            val walletPublicKey = "64DF67680F2167E1A085083FE3085561E6BEF5AA1FC165785FFAE6264706DB8C"
//                    .hexToBytes()
//            val signature = "C0FBC3255442CAE582FDC3CF8F431AAAB0B89D1D0DFBDAE71FEE44F99E4C11BD3D31BEB446589EDC761493C369CDA6B13AC09D122C58C7F5903832678371A96D"
//                    .hexToBytes()
//            val sendValue = "3".toBigDecimal()
//            val feeValue = "0.01".toBigDecimal()
//            val destinationAddress = "GAI3GJ2Q3B35AOZJ36C4ANE3HSS4NK7WI6DNO4ZSHRAX6NG7BMX6VJER"
//            val sequence = 123118694988529223L
//            val instant = 1612201818L
//            val token = Token(
//                    symbol = "MYNT",
//                    contractAddress = "GAHSHLZHWC3BGDDZ3JGUYXOHOQT4PCPL5WBQPGBXFB4OD3LG2MTOSRXD",
//                    decimals = 0
//            )
//
//            val walletAddress = StellarAddressService().makeAddress(walletPublicKey)
//            val calendar = Calendar.Builder().setInstant(instant).build()
//            val transactionBuilder =
//                    StellarTransactionBuilder(StellarNetworkServiceMock(), walletPublicKey, calendar)
//
//            val amountToSend = Amount(sendValue, blockchain, AmountType.Token(token))
//            val fee = Amount(feeValue, blockchain, AmountType.Coin)
//            val transactionData = TransactionData(
//                    sourceAddress = walletAddress,
//                    destinationAddress = destinationAddress,
//                    amount = amountToSend,
//                    fee = fee
//            )
//
//            val expectedHashToSign = "89632F5A2FD4A6D94859F3A0C53468489EFE8BCAF0AB3A89847775C2D7610749"
//                    .hexToBytes()
//            val expectedSignedTransaction = "AAAAAGTfZ2gPIWfhoIUIP+MIVWHmvvWqH8FleF/65iZHBtuMAAGGoAG1Z80AAD5IAAAAAQAAAAAAAAAAAAAAAAAYmiEAAAAAAAAAAQAAAAAAAAABAAAAABGzJ1DYd9A7Kd+FwDSbPKXGq/ZHhtdzMjxBfzTfCy/qAAAAAVhMTQAAAAAADyOvJ7C2Ewx52k1MXcd0J8eJ6+2DB5g3KHjh7WbTJukAAAAAAcnDgAAAAAAAAAABRwbbjAAAAEDA+8MlVELK5YL9w8+PQxqqsLidHQ372ucf7kT5nkwRvT0xvrRGWJ7cdhSTw2nNprE6wJ0SLFjH9ZA4MmeDcalt"
//
//            // act
//            val buildToSignResult = runBlocking {
//                transactionBuilder.buildToSign(transactionData, sequence) as Result.Success
//            }
//            val signedTransaction = transactionBuilder.buildToSend(signature)
//
//            // assert
//            Truth.assertThat(buildToSignResult.data).isEqualTo(expectedHashToSign)
//            Truth.assertThat(signedTransaction).isEqualTo(expectedSignedTransaction)
//        }

}
