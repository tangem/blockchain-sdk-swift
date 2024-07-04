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
        requestPublisher(for: request, map: parseQueryResponse(_:))
    }
    
    /// Send transaction data message for raw cell ICP
    /// - Parameter message: String data if cell message
    /// - Returns: Result of hash transaction
    func send(data: Data) -> AnyPublisher<Void, Error> {
        let target = ICPProviderTarget(node: node, requestType: .call, requestData: data)
        return requestPublisher(for: target, map: { _ in })
    }
    
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<CandidValue?, Error> {
        let target = ICPProviderTarget(node: node, requestType: .readState, requestData: data)
        return requestPublisher(for: target) { data in
            try? parseReadStateResponse(data, paths)
        }
    }
    
    // MARK: - Private Implementation
    
    private func requestData(from request: ICPRequest) throws -> Data {
        let content = try ICPRequestBuilder.buildContent(request)
        let envelope = ICPRequestEnvelope(content: content)
        return try CodableCBOREncoder().encode(envelope)
    }
    
    private func requestPublisher<T>(
        for request: ICPRequest,
        map: @escaping (Data) throws -> T
    ) -> AnyPublisher<T, Error> {
        do {
            return try requestPublisher(for: target(for: request), map: map)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private func target(for request: ICPRequest) throws -> ICPProviderTarget {
        let requestType = ICPRequestType.from(request)
        let data = try requestData(from: request)
        return ICPProviderTarget(node: node, requestType: requestType, requestData: data)
    }
    
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
    
    private func parseReadStateResponse(_ data: Data, _ paths: [ICPStateTreePath]) throws -> CandidValue? {
        let readStateResponse = try ICPCryptography.CBOR.deserialise(ReadStateResponseDecodable.self, from: data)
        let certificateCbor = try ICPCryptography.CBOR.deserialiseCbor(from: readStateResponse.certificate)
        let certificate = try ICPStateCertificate.parse(certificateCbor)
        let pathResponses = Dictionary(uniqueKeysWithValues: paths
            .map { ($0, certificate.tree.getValue(for: $0)) }
            .filter { $0.1 != nil }
            .map { ($0.0, $0.1!) }
        )
        
        let statusResponse = ICPReadStateResponse(stateValues: pathResponses)
        guard let statusString = statusResponse.stringValueForPath(endingWith: "status"),
              let status = ICPRequestStatusCode(rawValue: statusString) else {
            throw ICPPollingError.parsingError
        }
        switch status {
        case .done:
            throw ICPPollingError.requestIsDone
            
        case .rejected:
            guard let rejectCodeValue = statusResponse.rawValueForPath(endingWith: "reject_code"),
                  let rejectCode = ICPRequestRejectCode(rawValue: UInt8.from(rejectCodeValue)) else {
                throw ICPPollingError.parsingError
            }
            let rejectMessage = statusResponse.stringValueForPath(endingWith: "reject_message")
            throw ICPPollingError.requestRejected(rejectCode, rejectMessage)
            
        case .replied:
            guard let replyData = statusResponse.rawValueForPath(endingWith: "reply"),
                  let candidValue = try CandidDeserialiser().decode(replyData).first else {
                throw ICPPollingError.parsingError
            }
            return candidValue
            
        case .processing, .received:
            return nil
        }
    }
}

public enum ICPPollingError: Error {
    case malformedRequestId
    case requestIsDone
    case requestRejected(ICPRequestRejectCode, String?)
    case parsingError
    case timeout
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

public struct ICPReadStateResponse {
    public let stateValues: [ICPStateTreePath: Data]
       
    public func stringValueForPath(endingWith suffix: String) -> String? {
        guard let data = rawValueForPath(endingWith: suffix) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func rawValueForPath(endingWith suffix: String) -> Data? {
        stateValues.first { (path, value) in
            path.components.last?.stringValue == suffix
        }?.value
    }
}

