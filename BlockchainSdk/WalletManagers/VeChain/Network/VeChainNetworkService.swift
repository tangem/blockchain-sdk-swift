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
                    guard
                        let coinBalance = BigUInt(accountInfo.balance.removeHexPrefix(), radix: Constants.radix)?.decimal,
                        let energyBalance = BigUInt(accountInfo.energy.removeHexPrefix(), radix: Constants.radix)?.decimal
                    else {
                        throw WalletError.failedToParseNetworkResponse
                    }

                    let coinAmount = Amount(
                        with: networkService.blockchain,
                        value: coinBalance / networkService.blockchain.decimalValue
                    )

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
                .tryMap { blockInfo in
                    // The block ref is the first 8 bytes of the block id,
                    // see https://mirei83.medium.com/howto-vechain-blockchain-part-2-6ccd31f320c for details
                    let blockId = blockInfo.id
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
                        blockNumber: blockInfo.number
                    )
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
}

// MARK: - Constants

private extension VeChainNetworkService {
    enum Constants {
        static let radix = 16
        static let blockRefSize = 8
    }
}
