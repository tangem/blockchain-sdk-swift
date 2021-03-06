//
//  XRPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class XRPTransactionBuilder {
    var account: String? = nil
    var sequence: Int? = nil
    let walletPublicKey: Data
    let curve: EllipticCurve
    
    internal init(walletPublicKey: Data, curve: EllipticCurve) {
        var key: Data
        switch curve {
        case .secp256k1:
            key = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        case .ed25519:
            key = [UInt8(0xED)] + walletPublicKey
        case .secp256r1:
            fatalError("secp256r1 is not supported by XRP")
        }
        self.walletPublicKey = key
        self.curve = curve
    }
    
    public func buildForSign(transaction: Transaction) throws -> (XRPTransaction, Data)? {
        guard let tx = try buildTransaction(from: transaction) else {
            return nil
        }
        
        let dataToSign = tx.dataToSign(publicKey: walletPublicKey.asHexString())
        switch curve {
        case .ed25519:
            return (tx, dataToSign)
        case .secp256k1:
            return  (tx, dataToSign.sha512Half())
        case .secp256r1:
            fatalError("secp256r1 is not supported by XRP")
        }
    }
    
    public func buildForSend(transaction: XRPTransaction,  signature: Data) -> String?  {
        var sig: Data
        switch curve {
        case .ed25519:
            sig = signature
        case .secp256k1:
            guard let der = Secp256k1Utils.serializeToDer(secp256k1Signature: signature) else {
                return nil
            }
            
            sig = der
        case .secp256r1:
            fatalError("secp256r1 is not supported by XRP")
        }
        
        guard let signedTx = try? transaction.sign(signature: sig.toBytes) else {
            return nil
        }
        
        let blob = signedTx.getBlob()
        return blob
    }
    
    private func buildTransaction(from transaction: Transaction) throws -> XRPTransaction? {
        guard let account = account, let sequence = sequence else {
                return nil
        }
         
        let amountDrops = (transaction.amount.value * Decimal(1000000)).rounded(blockchain: .xrp(curve: curve))
        let feeDrops = (transaction.fee.value * Decimal(1000000)).rounded(blockchain: .xrp(curve: curve))
        
        let decodedXAddress = try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress)
        let destination = decodedXAddress?.rAddress ?? transaction.destinationAddress
        
        let decodedTag = decodedXAddress?.tag
        let explicitTag = (transaction.params as? XRPTransactionParams)?.destinationTag
        
        let destinationTag: UInt32? = try {
            switch (decodedTag, explicitTag) {
            case (.some(let tag), .none):
                return tag
            case (.none, .some(let tag)):
                return tag
            case (.some(let tag1), .some(let tag2)):
                if tag1 != tag2 {
                    throw XRPError.distinctTagsFound
                }
                return tag1
            case (.none, .none): return nil
            }
        }()
        
         // dictionary containing partial transaction fields
         var fields: [String:Any] = [
             "Account" : account,
             "TransactionType" : "Payment",
             "Destination" : destination,
             "Amount" : "\(amountDrops)",
             // "Flags" : UInt64(2147483648),
             "Fee" : "\(feeDrops)",
             "Sequence" : sequence,
         ]
        
        if destinationTag != nil {
            fields["DestinationTag"] = destinationTag
        }
         
         // create the transaction from dictionary
         return XRPTransaction(fields: fields)
    }
}
