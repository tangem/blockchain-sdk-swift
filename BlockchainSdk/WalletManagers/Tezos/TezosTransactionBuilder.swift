//
//  TezosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import stellarsdk

class TezosTransactionBuilder {
    var counter: Int? = nil
    var isPublicKeyRevealed: Bool? = nil
    
    private let walletPublicKey: Data

    internal init(walletPublicKey: Data) {
        self.walletPublicKey = walletPublicKey
    }
    
    func buildToSign(forgedContents: String) -> Data? {
        let genericOperationWatermark = "03"
        let message = Data(hex: genericOperationWatermark + forgedContents).bytes
        return Sodium().genericHash.hash(message: message, outputLength: 32).map { Data($0) }
    }

    func buildToSend(signature: Data, forgedContents: String) -> String {
        return forgedContents + signature.asHexString()
    }
    
    func buildContents(transaction: Transaction) -> [TezosOperationContent]? {
        guard var counter = self.counter, let isPublicKeyRevealed = self.isPublicKeyRevealed else {
            return nil
        }
        
        var contents = [TezosOperationContent]()
        contents.reserveCapacity(isPublicKeyRevealed ? 1 : 2)

        if !isPublicKeyRevealed {
            counter += 1
            let revealOp = TezosOperationContent(
                kind: "reveal",
                source: transaction.sourceAddress,
                fee: TezosFee.reveal.mutezValue,
                counter: counter.description,
                gasLimit: "10000",
                storageLimit:  "0",
                publicKey: encodePublicKey(walletPublicKey),
                destination: nil,
                amount: nil)
            
            contents.append(revealOp)
        }

        counter += 1
        let transactionOp = TezosOperationContent(
            kind: "transaction",
            source: transaction.sourceAddress,
            fee: TezosFee.transaction.mutezValue,
            counter: counter.description,
            gasLimit:  "10600",
            storageLimit:  "300", // set it to 0?
            publicKey: nil,
            destination: transaction.destinationAddress,
            amount: (transaction.amount.value * pow(10, Blockchain.tezos.decimalCount)).description)
        
        contents.append(transactionOp)
        return contents
    }
    
    private func encodePublicKey(_ pkUncompressed: Data) -> String {
        let edpkPrefix = Data(hex: "0D0F25D9")
        let prefixedPubKey = edpkPrefix + pkUncompressed

        let checksum = prefixedPubKey.sha256().sha256().prefix(4)
        let prefixedHashWithChecksum = prefixedPubKey + checksum

        return Base58.encode(prefixedHashWithChecksum)
    }
}
