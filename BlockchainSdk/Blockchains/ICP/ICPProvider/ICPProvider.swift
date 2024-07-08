//
//  ICPProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import IcpKit

struct ICPProvider: HostProvider {
    /// Blockchain API host
    var host: String {
        node.url.hostOrUnknown
    }
    
    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties
    
    /// Network provider of blockchain
    private let network: NetworkProvider<ICPProviderTarget>
    
    private let responseParser: ResponseParser
    
    // MARK: - Init
    
    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration,
        responseParser: ResponseParser
    ) {
        self.node = node
        self.network = .init(configuration: networkConfig)
        self.responseParser = responseParser
    }
    
    // MARK: - Implementation
    
    /// Fetch full information about wallet address
    /// - Parameter data: CBOR-encoded ICPRequestEnvelope
    /// - Returns: account balance
    func getInfo(data: Data) -> AnyPublisher<Decimal, Error> {
        let target = ICPProviderTarget(node: node, requestType: .query, requestData: data)
        return requestPublisher(for: target, map: responseParser.parseAccountBalanceResponse(_:) )
    }
    
    /// Send transaction data message for raw cell ICP
    /// - Parameter data: CBOR-encoded ICPRequestEnvelope
    /// - Returns: Result of hash transaction
    func send(data: Data) -> AnyPublisher<Void, Error> {
        let target = ICPProviderTarget(node: node, requestType: .call, requestData: data)
        return requestPublisher(for: target, map: responseParser.parseTransferResponse(_:) )
    }
    
    /// Send transaction data message for raw cell ICP
    /// - Parameter data: CBOR-encoded ICPRequestEnvelope
    /// - Returns: Result of hash transaction
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64?, Error> {
        let target = ICPProviderTarget(node: node, requestType: .readState, requestData: data)
        return requestPublisher(for: target) { [responseParser] data in
            try? responseParser.parseTranserStateResponse(data, paths: paths)
        }
    }
    
    // MARK: - Private Implementation
    
    private func requestPublisher<T>(
        for target: ICPProviderTarget,
        map: @escaping (Data) throws -> T
    ) -> AnyPublisher<T, Error> {
        network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap { response in
                try map(response.data)
            }
            .mapError { _ in WalletError.empty }
            .eraseToAnyPublisher()
    }
}

