//
//  VeChainNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

final class VeChainNetworkService: MultiNetworkProvider {
    let providers: [VeChainNetworkProvider]
    var currentProviderIndex: Int

    private let blockchain: Blockchain
    private let energyToken: Token

    init(
        blockchain: Blockchain,
        energyToken: Token,
        providers: [VeChainNetworkProvider]
    ) {
        self.blockchain = blockchain
        self.energyToken = energyToken
        self.providers = providers
        currentProviderIndex = 0
    }

    func getAccountInfo(address: String) -> AnyPublisher<VeChainAccountInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getAccountInfo(address: address)
                .withWeakCaptureOf(self)
                .tryMap { networkService, accountInfo in
                    let coinBalance = try networkService.mapDecimalValue(from: accountInfo.balance)
                    let coinAmount = Amount(
                        with: networkService.blockchain,
                        value: coinBalance / networkService.blockchain.decimalValue
                    )

                    let energyBalance = try networkService.mapDecimalValue(from: accountInfo.energy)
                    let energyAmount = Amount(
                        with: networkService.blockchain,
                        type: .token(value: networkService.energyToken),
                        value: energyBalance / networkService.energyToken.decimalValue
                    )

                    return VeChainAccountInfo(
                        amount: coinAmount,
                        tokenAmounts: [energyAmount]
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getLatestBlockInfo() -> AnyPublisher<VeChainBlockInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getBlockInfo(request: .init(requestType: .latest, isExpanded: false))
                .withWeakCaptureOf(self)
                .tryMap { networkService, blockInfo in
                    return try networkService.mapBlockInfo(from: blockInfo)
                }
                .eraseToAnyPublisher()
        }
    }

    func getTransactionInfo(transactionHash: String) -> AnyPublisher<VeChainTransactionInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getTransactionStatus(request: .init(hash: transactionHash, includePending: false, rawOutput: false))
                .tryMap { transactionStatus in
                    switch transactionStatus {
                    case .parsed(let parsedStatus):
                        VeChainTransactionInfo(transactionHash: parsedStatus.id)
                    case .raw:
                        // `raw` output can't be easily parsed and therefore not supported
                        throw WalletError.failedToParseNetworkResponse
                    case .notFound:
                        VeChainTransactionInfo(transactionHash: nil)
                    }
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: Data) -> AnyPublisher<TransactionSendResult, Error> {
        let rawTransaction = transaction.hexString.lowercased().addHexPrefix()

        return providerPublisher { provider in
            return provider
                .sendTransaction(rawTransaction)
                .map { TransactionSendResult(hash: $0.id) }
                .mapError { error in
                    if let error = error as? WalletError {
                        return error
                    }

                    return WalletError.failedToSendTx
                }
                .eraseToAnyPublisher()
        }
    }

    private func mapDecimalValue(from balance: String) throws -> Decimal {
        guard
            let bigUIntValue = BigUInt(balance.removeHexPrefix(), radix: Constants.radix),
            let decimalValue = bigUIntValue.decimal
        else {
            throw WalletError.failedToParseNetworkResponse
        }

        return decimalValue
    }

    private func mapBlockInfo(from blockInfoDTO: VeChainNetworkResult.BlockInfo) throws -> VeChainBlockInfo {
        // The block ref is the first 8 bytes of the block id,
        // see https://mirei83.medium.com/howto-vechain-blockchain-part-2-6ccd31f320c for details
        let blockId = blockInfoDTO.id
        let rawBlockRef = blockId.removeHexPrefix().prefix(Constants.blockRefSize * 2)

        guard
            rawBlockRef.count == Constants.blockRefSize * 2,
            let blockRef = UInt(rawBlockRef, radix: Constants.radix)
        else {
            throw WalletError.failedToParseNetworkResponse
        }

        return VeChainBlockInfo(
            blockId: blockId,
            blockRef: blockRef,
            blockNumber: blockInfoDTO.number
        )
    }
}

// MARK: - Constants

private extension VeChainNetworkService {
    enum Constants {
        static let radix = 16
        static let blockRefSize = 8
    }
}
