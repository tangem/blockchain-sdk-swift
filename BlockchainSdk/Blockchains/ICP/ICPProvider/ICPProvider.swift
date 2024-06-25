//
//  ICPProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftCBOR

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
    
    // MARK: - Init
    
    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        self.network = .init(configuration: networkConfig)
    }
    
    // MARK: - Implementation
    
    /// Fetch full information about wallet address
    /// - Parameter address: ICP address wallet
    /// - Returns: account balance
    func getInfo(request: ICPRequest) -> AnyPublisher<CandidValue, Error> {
        requestPublisher(for: request)
    }
    
    /// Send transaction data message for raw cell ICP
    /// - Parameter message: String data if cell message
    /// - Returns: Result of hash transaction
    func send(request: ICPRequest) -> AnyPublisher<CandidValue, Error> {
        requestPublisher(for: request)
    }
    
    // MARK: - Private Implementation
    
    private func requestData(from request: ICPRequest) throws -> Data {
        let content = try ICPRequestBuilder.buildContent(request)
        let envelope = ICPRequestEnvelope(content: content)
        return try CodableCBOREncoder().encode(envelope)
    }
    
    private func requestPublisher(for request: ICPRequest) -> AnyPublisher<CandidValue, Error> {
        do {
            let requestType = ICPRequestType.from(request)
            let data = try requestData(from: request)
            let target = ICPProviderTarget(node: node, requestType: requestType, requestData: data)
            
            return network.requestPublisher(target)
                .filterSuccessfulStatusAndRedirectCodes()
                .tryMap { response in
                    try parseQueryResponse(response.data)
                }
                .mapError { _ in WalletError.empty }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private func parseQueryResponse(_ data: Data) throws -> CandidValue {
        guard let cbor = try CBOR.decode(data.bytes),
              let queryResponse = QueryResponseDecodable(cbor: cbor) else {
            throw WalletError.failedToParseNetworkResponse
        }
        
        guard queryResponse.status != .rejected else {
            throw WalletError.empty
        }
        guard let candidRaw = queryResponse.reply?.arg else {
            throw WalletError.failedToParseNetworkResponse
        }
        let candidResponse = try CandidDeserialiser().decode(candidRaw)
        guard let firstCandidValue = candidResponse.first else {
            throw WalletError.failedToParseNetworkResponse
        }
        return firstCandidValue
    }
}

public enum ICPRequestRejectCode: UInt8, Decodable {
    case systemFatal = 1
    case systemTransient = 2
    case destinationInvalid = 3
    case canisterReject = 4
    case canisterError = 5
}

public enum ICPRequestStatusCode: String, Decodable {
    case received
    case processing
    case replied
    case rejected
    case done
}

fileprivate struct QueryResponseDecodable: Decodable {
    let status: ICPRequestStatusCode
    let reply: Reply?
    
    struct Reply: Decodable {
        let arg: Data
    }
    
    init?(cbor: CBOR) {
        guard case .tagged(_, let cBOR) = cbor,
            case .map(let dictionary) = cBOR else {
            return nil
        }
        guard let statusValue = dictionary[.utf8String("status")],
              case .utf8String(let statusString) = statusValue,
              let status = ICPRequestStatusCode(rawValue: statusString) else {
                  return nil
              }
        self.status = status
        
        guard let reply = dictionary[.utf8String("reply")],
              case .map(let dictionary) = reply  else {
            return nil
        }
        
        guard let argValue = dictionary[.utf8String("arg")],
              case .byteString(let byteArray) = argValue else {
                  return nil
              }
        self.reply = Reply(arg: Data(byteArray))
    }
}

private struct ReadStateResponseDecodable: Decodable {
    let certificate: Data
}
