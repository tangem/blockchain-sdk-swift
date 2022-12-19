//
//  EVMTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 24.11.2022.
//

import Foundation
import Moya

struct EvmTargetBuilder {
    let baseURL: URL
    let blockchain: Blockchain
    var apiKey: String?
    
    func balance(address: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .balance(address: address)))
    }
    
    func transactions(address: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .transactions(address: address)))
    }
    
    func pending(address: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .pending(address: address)))
    }
    
    func send(transaction: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .send(transaction: transaction)))
    }
    
    func tokenBalance(address: String, contractAddress: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .tokenBalance(address: address, contractAddress: contractAddress)))
    }
    
    func getAllowance(from source: String, to destination: String, contractAddress: String) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .getAllowance(from: source, to: destination, contractAddress: contractAddress)))
    }
    
    func gasLimit(to: String, from: String, value: String?, data: String?) -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .gasLimit(to: to, from: from, value: value, data: data)))
    }
    
    func gasPrice() -> EvmRawTarget {
        EvmRawTarget(apiKey: apiKey,
                     baseURL: baseURL,
                     parameters: buildParameters(for: .gasPrice))
    }
}

extension EvmTargetBuilder {
    private enum EvmRequest {
        case balance(address: String)
        case transactions(address: String)
        case pending(address: String)
        case send(transaction: String)
        case tokenBalance(address: String, contractAddress: String)
        case getAllowance(from: String, to: String, contractAddress: String)
        case gasLimit(to: String, from: String, value: String?, data: String?)
        case gasPrice
    }
    
    private func buildParameters(for request: EvmRequest) -> [String: Any] {
        var parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": evmMethod(for: request),
            "id": blockchain.chainId
        ]
        
        var params: [Any] = []
        switch request {
        case .balance(let address), .transactions(let address), .pending(let address):
            params.append(address)
        case .send(let transaction):
            params.append(transaction)
        case .tokenBalance(let address, let contractAddress):
            let rawAddress = address.removeHexPrefix()
            let dataValue = ["data": "0x70a08231000000000000000000000000\(rawAddress)", "to": contractAddress]
            params.append(dataValue)
        case .getAllowance(let fromAddress, let toAddress, let contractAddress):
            let dataValue = ["data": "0xdd62ed3e\(fromAddress.serialize())\(toAddress.serialize())",
                             "to": contractAddress]
            params.append(dataValue)
        case .gasLimit(let to, let from, let value, let data):
            var gasLimitParams = [String: String]()
            gasLimitParams["from"] = from
            gasLimitParams["to"] = to
            if let value = value {
                gasLimitParams["value"] = value
            }
            if let data = data {
                gasLimitParams["data"] = data
            }
            params.append(gasLimitParams)
        case .gasPrice:
            break
        }
        
        if let blockParams = blockParamerers(for: request) {
            params.append(blockParams)
        }
        parameters["params"] = params
        return parameters
    }
    
    private func evmMethod(for request: EvmRequest) -> String {
        switch request {
        case .balance: return "\(prefix())_getBalance"
        case .transactions, .pending: return "\(prefix())_getTransactionCount"
        case .send: return "\(prefix())_sendRawTransaction"
        case .tokenBalance, .getAllowance: return "\(prefix())_call"
        case .gasLimit: return "\(prefix())_estimateGas"
        case .gasPrice: return "\(prefix())_gasPrice"
        }
    }
    
    private func blockParamerers(for request: EvmRequest) -> String? {
        switch request {
        case .balance, .transactions, .tokenBalance, .getAllowance: return "latest"
        case .pending: return "pending"
        case .send, .gasLimit, .gasPrice: return nil
        }
    }
    
    private func prefix() -> String {
        switch blockchain {
        case .bsc, .ethereum, .avalanche, .ethereumClassic, .ethereumPoW, .fantom, .optimism, .polygon:
            if baseURL.absoluteString.contains("nownodes") {
                return blockchain.currencySymbol.lowercased()
            } else {
                return "eth"
            }
        case .ethereumFair, .arbitrum, .gnosis, .rsk:
            return "eth"
        default:
            fatalError()
        }
    }
}
