//
//  OneAddressWallet.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 13.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PlainWallet: BaseWalletType {
    public let blockchain: Blockchain
    public var transactions: [Transaction]
    public var amounts: [Amount.AmountType : Amount]

    public let address: String
    public let publicKey: Wallet.PublicKey
}

//struct MultiAddressWallet: BaseWalletType {
//    public let blockchain: Blockchain
//    public var transactions: [Transaction]
//    public var amounts: [Amount.AmountType : Amount]
//
//    public let walletAddresses: [AddressType: AddressPublicKeyPair]
//}

struct TokensWallet: BaseWalletType {
    public let blockchain: Blockchain
    public var transactions: [Transaction]
    public var amounts: [Amount.AmountType : Amount]

    public let address: String
    public let publicKey: Wallet.PublicKey

    public var tokens: [Token]
}
