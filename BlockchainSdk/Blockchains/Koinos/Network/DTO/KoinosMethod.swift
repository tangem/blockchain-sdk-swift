//
//  KoinosMethod.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: [KOINOS] Invent more suitable naming
// https://tangem.atlassian.net/browse/IOS-6758
enum KoinosMethod {}

extension KoinosMethod {
    enum ReadContract {
        struct RequestParams: Encodable {
            let contractId: String
            let entryPoint: Int
            let args: String
        }
        
        struct Response: Decodable {
            let result: String?
        }
    }
}

extension KoinosMethod {
    enum GetAccountRC {
        struct RequestParams: Encodable {
            let account: String
        }
        
        struct Response: Decodable {
            let rc: UInt64
            
            enum CodingKeys: CodingKey {
                case rc
            }
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: KoinosMethod.GetAccountRC.Response.CodingKeys.self)
                let stringRC = try container.decodeIfPresent(String.self, forKey: KoinosMethod.GetAccountRC.Response.CodingKeys.rc)
                
                self.rc = if let stringRC, let rc = UInt64(stringRC) {
                    rc
                } else {
                    0
                }
            }
        }
    }
}

extension KoinosMethod {
    enum GetAccountNonce {
        struct RequestParams: Encodable {
            let account: String
        }
        
        struct Response: Decodable {
            let nonce: UInt64
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let base64EncodedNonce: String = try container.decode(forKey: .nonce)
                
                guard let data = base64EncodedNonce.base64URLDecodedData(),
                      let type = try? Koinos_Chain_value_type(serializedData: data)
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                self.nonce = type.uint64Value
            }
            
            enum CodingKeys: String, CodingKey {
                case nonce
            }
        }
    }
}

extension KoinosMethod {
    enum GetResourceLimits {
        struct Response: Decodable {
            let resourceLimitData: KoinosChain.ResourceLimitData
        }
    }
}

extension KoinosMethod {
    enum SubmitTransaction {
        struct RequestParams: Encodable {
            let transaction: KoinosProtocol.Transaction
            let broadcast: Bool
        }
        
        struct Response: Decodable {
            let receipt: KoinosProtocol.TransactionReceipt
        }
    }
    
}
