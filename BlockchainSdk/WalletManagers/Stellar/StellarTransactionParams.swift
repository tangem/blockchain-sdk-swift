//
//  StellarTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

public enum StellarTransactionParams: TransactionParams {
    case memo(StellarMemo)
    
    var memo: StellarMemo? {
        switch self {
        case .memo(let memo):
            return memo
        }
    }
}

public typealias StellarMemo = Memo

