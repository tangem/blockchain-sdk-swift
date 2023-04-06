//
//  TONTransactionParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore

public struct TONTransactionParams: TransactionParams {
    public var memo: Memo?
    
    public init(memo: Memo? = nil) {
        self.memo = memo
    }
}

extension TONTransactionParams {
    
    public enum Memo {
        case none
        case text (String)
        
        var value: String? {
            switch self {
            case .text(let text):
                return text
            case .none:
                return nil
            }
        }
    }
    
}
