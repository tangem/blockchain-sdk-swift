//
//  CosmosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

class CosmosTransactionBuilder {
    private let cosmosChain: CosmosChain
    private var sequenceNumber: UInt64?
    private var accountNumber: UInt64?
    
    private var regularGasPrice: Double {
        cosmosChain.gasPrices[1]
    }
    
    init(cosmosChain: CosmosChain) {
        self.cosmosChain = cosmosChain
    }
    
    func setSequenceNumber(_ sequenceNumber: UInt64) {
        self.sequenceNumber = sequenceNumber
    }
    
    func setAccountNumber(_ accountNumber: UInt64) {
        self.accountNumber = accountNumber
    }
    
    func buildForSign(amount: Amount, destination: String, gasPrice: Double, gas: UInt64?) throws -> CosmosSigningInput {
        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f004"))!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: true)
        let fromAddress = AnyAddress(publicKey: publicKey, coin: .cosmos)
        
        
        let amountInSmallestDenomination = ((amount.value * cosmosChain.blockchain.decimalValue) as NSDecimalNumber).uint64Value
        
        let sendCoinsMessage = CosmosMessage.Send.with {
            $0.fromAddress = fromAddress.description
            $0.toAddress = destination
            $0.amounts = [CosmosAmount.with {
                $0.amount = "\(amountInSmallestDenomination)"
                $0.denom = cosmosChain.smallestDenomination
            }]
        }

        let message = CosmosMessage.with {
            $0.sendCoinsMessage = sendCoinsMessage
        }
        
        let fee: CosmosFee?
        if let gas = gas {
            let feeAmount = Int(Double(gas) * gasPrice)
            
            fee = CosmosFee.with {
                $0.gas = gas
                $0.amounts = [CosmosAmount.with {
                    $0.amount = "\(feeAmount)"
                    $0.denom = cosmosChain.smallestDenomination
                }]
            }
        } else {
            fee = nil
        }
        
        guard
            let accountNumber = self.accountNumber,
            let sequenceNumber = self.sequenceNumber
        else {
            throw WalletError.failedToBuildTx
        }

        var input = CosmosSigningInput.with {
            $0.signingMode = .protobuf;
            $0.accountNumber = accountNumber
            $0.chainID = cosmosChain.chainID
            $0.memo = ""
            $0.sequence = sequenceNumber
            $0.messages = [message]
            if let fee = fee {
                $0.fee = fee
            }
            $0.privateKey = privateKey.data
        }
        
        return input
    }
}
