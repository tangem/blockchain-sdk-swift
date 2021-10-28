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
import TangemSdk

class TezosTransactionBuilder {
    var counter: Int? = nil
    var isPublicKeyRevealed: Bool? = nil
    
    private let walletPublicKey: Data
    private let curve: EllipticCurve
    
    internal init(walletPublicKey: Data, curve: EllipticCurve) {
        switch curve {
        case .ed25519:
            self.walletPublicKey = walletPublicKey
        case .secp256k1:
            self.walletPublicKey = Secp256k1Utils.compressPublicKey(walletPublicKey)!
        case .secp256r1:
            fatalError("Not implemented")
        }
        self.curve = curve
    }
    
    func buildToSign(forgedContents: String) -> Data? {
        let genericOperationWatermark = Data(TezosPrefix.Watermark.operation)
        let message = genericOperationWatermark + Data(hex: forgedContents)
        return Sodium().genericHash.hash(message: message.bytes, outputLength: 32).map { Data($0) }
    }

    func buildToSend(signature: Data, forgedContents: String) -> String {
        return forgedContents + signature.hexString
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
                publicKey: encodePublicKey(),
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
            amount: (transaction.amount.value * Blockchain.tezos(curve: .ed25519).decimalValue).description)
        
        contents.append(transactionOp)
        return contents
    }
    
    private func encodePublicKey() -> String {
        let publicPrefix = TezosPrefix.publicPrefix(for: curve)
        let prefixedPubKey = publicPrefix + walletPublicKey
        
        let checksum = prefixedPubKey.sha256().sha256().prefix(4)
        let prefixedHashWithChecksum = prefixedPubKey + checksum

        return Base58.encode(prefixedHashWithChecksum)
    }
}
