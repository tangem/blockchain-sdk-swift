//
//  Card+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 05.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Card {
    public var blockchain: Blockchain? {
        if let name = cardData?.blockchainName,
           let curve = curve {
            return Blockchain.from(blockchainName: name, curve: curve)
        }
        return nil
    }
    
    public var token:  Token? {
        if let symbol = cardData?.tokenSymbol,
           let contractAddress = cardData?.tokenContractAddress,
           let decimal = cardData?.tokenDecimal {
            return Token(symbol: symbol,
                         contractAddress: contractAddress,
                         decimalCount: decimal)
        }
        return nil
    }
    
    public var isTestnet: Bool {
        return blockchain?.isTestnet ?? false
    }
}
