//
//  EthereumOptimisticRollupWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya

// Used by Optimism, Base, and other Ethereum L2s with optimistic rollups.
final class EthereumOptimisticRollupWalletManager: EthereumWalletManager {
    /// We are override this method to combine the two fee's layers in the `Optimistic-Ethereum` network.
    /// Read more:
    /// https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    /// https://help.optimism.io/hc/en-us/articles/4411895794715-How-do-transaction-fees-on-Optimism-work
    /// Short information:
    /// `L2` - Used to provide this transaction in the `Optimistic-etherium` network like a usual tx.
    /// `L1` - Used to processing a transaction in the `Etherium` network  for "safety".
    /// This L1 fee will be added to the transaction fee automatically after it is sent to the network.
    /// This L1 fee calculated the Optimism smart-contract oracle.
    /// This L1 fee have to used ONLY for showing to a user.
    /// When we're building transaction we have to used `gasLimit` and `gasPrice` ONLY from `L2`
    override func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        super.getFee(destination: destination, value: value, data: data)
            .flatMap { [weak self] layer2Fees -> AnyPublisher<([Fee], Decimal), Error> in
                guard let self,
                      // We use EthereumFeeParameters without increase
                      let parameters = layer2Fees.first?.parameters as? EthereumFeeParameters else {
                    return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
                }

                return self.getLayer1Fee(
                    destination: destination,
                    value: value,
                    data: data,
                    l2FeeParameters: parameters
                )
                .map { (layer2Fees, $0) }
                .eraseToAnyPublisher()
            }
            .map { layer2Fees, layer1Fee -> [Fee] in
                layer2Fees.map { fee in
                    let newAmount = Amount(with: fee.amount, value: fee.amount.value + layer1Fee)
                    let newFee = Fee(newAmount, parameters: fee.parameters)
                    return newFee
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension EthereumOptimisticRollupWalletManager {
    func getLayer1Fee(
        destination: String,
        value: String?,
        data: Data?,
        l2FeeParameters: EthereumFeeParameters
    ) -> AnyPublisher<Decimal, Error> {
        let valueData = Data(hex: value ?? "0x0")
        let transaction = EthereumTransaction(
            nonce: BigUInt(0),
            gasPrice: l2FeeParameters.gasPrice,
            gasLimit: l2FeeParameters.gasLimit,
            to: destination,
            value: BigUInt(valueData),
            data: data ?? Data()
        )

        // Just collect data to get estimated fee from contact address
        // https://github.com/ethereum/wiki/wiki/RLP
        guard let rlpEncodedTransactionData = transaction.encode(forSignature: false) else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }

        return networkService
            .read(target: EthereumOptimisticRollupSmartContract.getL1Fee(data: rlpEncodedTransactionData))
            .tryMap { [wallet] response in
                guard let value = EthereumUtils.parseEthereumDecimal(response, decimalsCount: wallet.blockchain.decimalCount) else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return value
            }
            // We can ignore errors so as not to block users
            // This L1Fee value is only needed to inform users. It will not used in the transaction
            // Unfortunately L1 fee doesn't work well
            .replaceError(with: 0)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
