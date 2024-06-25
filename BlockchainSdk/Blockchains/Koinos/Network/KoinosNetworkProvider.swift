//
//  KoinosNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 23.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class KoinosNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }
    
    private let node: NodeInfo
    private let provider: NetworkProvider<KoinosTarget>
    private let koinContractAbi: KoinContractAbi
    
    init(node: NodeInfo, koinContractAbi: KoinContractAbi, configuration: NetworkProviderConfiguration) {
        self.node = node
        provider = NetworkProvider<KoinosTarget>(configuration: configuration)
        self.koinContractAbi = koinContractAbi
    }
    
    func getKoinBalance(address: String) throws -> AnyPublisher<UInt64, Never> {
        let args = try Koinos_Contracts_Token_balance_of_arguments.with {
            $0.owner = address.base58DecodedData
        }
        .serializedData()
        .base64URLEncodedString()
        
        return requestPublisher(
            for: .getKoinBalance(args: args),
            withResponseType: KoinosMethod.ReadContract.Response.self
        )
        .tryMap { response in
            guard let result = response.result, let decodedResult = result.base64URLDecodedData() else {
                return 0
            }
            return try Koinos_Contracts_Token_balance_of_result(serializedData: decodedResult).value
        }
        .replaceError(with: 0)
        .eraseToAnyPublisher()
    }
    
    func getRC(address: String) -> AnyPublisher<UInt64, Never> {
        requestPublisher(
            for: .getRc(address: address),
            withResponseType: KoinosMethod.GetAccountRC.Response.self
        )
        .map(\.rc)
        .replaceError(with: 0)
        .eraseToAnyPublisher()
    }
    
    func getNonce(address: String) -> AnyPublisher<UInt64, Error> {
        requestPublisher(
            for: .getNonce(address: address),
            withResponseType: KoinosMethod.GetAccountNonce.Response.self
        )
        .map(\.nonce)
        .eraseToAnyPublisher()
    }
    
    func getResourceLimits() -> AnyPublisher<KoinosChain.ResourceLimitData, Error> {
        requestPublisher(
            for: .getResourceLimits,
            withResponseType: KoinosMethod.GetResourceLimits.Response.self
        )
        .map(\.resourceLimitData)
        .eraseToAnyPublisher()
    }
    
    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosTransactionEntry, Error> {
        requestPublisher(
            for: .submitTransaction(transaction: transaction),
            withResponseType: KoinosMethod.SubmitTransaction.Response.self,
            decoder: .init()
        )
        .map(\.receipt)
        .tryMap { receipt in
            guard let encodedEvent = receipt.events.first?.eventData, let data = encodedEvent.base64URLDecodedData() else {
                throw WalletError.failedToParseNetworkResponse
            }
            
            let decodedEvent = try Koinos_Contracts_Token_transfer_event(serializedData: data)
            
            return KoinosTransactionEntry(
                id: receipt.id,
                sequenceNum: UInt64.max,
                payerAddress: receipt.payer,
                rcLimit: receipt.maxPayerRc,
                rcUsed: receipt.rcUsed,
                event: KoinosTransferEvent(
                    fromAccount: decodedEvent.from.base58EncodedString,
                    toAccount: decodedEvent.to.base58EncodedString,
                    value: decodedEvent.value
                )
            )
        }
        .eraseToAnyPublisher()
    }
    
    private func requestPublisher<T: Decodable>(
        for target: KoinosTarget.KoinosTargetType,
        withResponseType: T.Type,
        decoder: JSONDecoder = .withSnakeCaseStrategy
    ) -> AnyPublisher<T, Error> {
        provider.requestPublisher(KoinosTarget(node: node, koinContractAbi: koinContractAbi, target))
            .filterSuccessfulStatusAndRedirectCodes()
            // TODO: [KOINOS] Chnage NEARNetworkResult.APIError to something KOINOS related
            .map(JSONRPC.Response<T, NEARNetworkResult.APIError>.self, using: decoder)
            .mapError { moyaError in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse as Error
                }
                return moyaError
            }
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
