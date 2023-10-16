//
//  NEARWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt   // FIXME: Andrey Fedorov - Test only, remove when not needed

final class NEARWalletManager: BaseManager {
    private let networkService: NEARNetworkService
    private let transactionBuilder: NEARTransactionBuilder

    init(
        wallet: Wallet,
        networkService: NEARNetworkService,
        transactionBuilder: NEARTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(accountId: wallet.address)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        self.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] value in
                    self?.wallet.add(amount: value.amount)
                }
            )
    }
}

// MARK: - WalletManager protocol conformance

extension NEARWalletManager: WalletManager {
    var currentHost: String {
        fatalError("\(#function) not implemented yet!")
    }

    var allowsFeeSelection: Bool {
        return false
    }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        // https://docs.near.org/concepts/basics/transactions/gas

        let _value: Decimal = 0.000446365125000
        let amount = Amount(with: wallet.blockchain, value: _value)
        let fees = [Fee(amount)]

        return Just(fees)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        fatalError()
//        return Deferred { [transactionBuilder = self.transactionBuilder] in
//            Future { promise in
//                do {
//                    let output = try transactionBuilder.buildForSign(transaction: transaction)
//                    promise(.success(output))
//                } catch {
//                    promise(.failure(error))
//                }
//            }
//        }
//        .withWeakCaptureOf(self)
//        .flatMap { walletManager, output in
//            return signer.sign(hash: output, walletPublicKey: walletManager.wallet.publicKey)
//        }
//        .map { _ in
//            TransactionSendResult(hash: "") // FIXME: Andrey Fedorov - Test only, remove when not needed
//        }
//        .eraseToAnyPublisher()
    }
}
