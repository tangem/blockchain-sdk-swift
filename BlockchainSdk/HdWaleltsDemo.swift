//
//  HdWaleltsDemo.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 19.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
func makePublicKey(for card: Card) throws -> PublicKey {
    let wallet: Card.Wallet! = card.wallets.filter({ $0.curve == .secp256k1 }).first //XRP wallets in TangemApp are always based on secp256k1
    
    if let chainCode = wallet.chainCode { //New cards with hdWallets feature enabled
        
        let bip44 = BIP44(coinType: 144, //XRP coin type
                          account: 0,
                          change: .external,
                          addressIndex: 0)
        
        let hdPath =  bip44.buildPath().toNonHardened() //make path
        let extendedKey = ExtendedPublicKey(compressedPublicKey: wallet.publicKey, chainCode: chainCode)
        let derivedKey = try extendedKey.derivePublicKey(path: hdPath).compressedPublicKey //derive key
        
        return PublicKey(publicKeyForSigning: wallet.publicKey,
                         hdPathForSigning: hdPath,
                         publicKeyForBlockchain: derivedKey)
        
    } else { //old cards
        return PublicKey(publicKeyForSigning: wallet.publicKey,
                         hdPathForSigning: nil,
                         publicKeyForBlockchain: wallet.publicKey)
    }
}

func signHash(_ hash: Data, cardId: String, with publicKey: PublicKey, signer: TangemSdk, completion: @escaping (Result<Data, Error>) -> Void) {
    signer.sign(hash: hash,
                walletPublicKey: publicKey.publicKeyForSigning,
                cardId: cardId,
                hdPath: publicKey.hdPathForSigning) {_ in
        //...
        //completion()
    }
}

func makeAddress(from key: PublicKey) -> String {
    let publicKey = Secp256k1Utils.compressPublicKey(key.publicKeyForBlockchain)! //compress if needed. (old cards)
    let input = RIPEMD160.hash(message: publicKey.sha256())
    let buffer = [0x00] + input
    let checkSum = Data(buffer.sha256().sha256()[0..<4])
    return String(base58: buffer + checkSum, alphabet: Base58String.xrpAlphabet)
}

struct PublicKey {
    let publicKeyForSigning: Data
    let hdPathForSigning: DerivationPath?
    let publicKeyForBlockchain: Data
}
