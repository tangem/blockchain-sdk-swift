//
//  XRPTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum XRPTransactionParams: TransactionParams {
    case destinationTag(String)
    
    var destinationTag: UInt32? {
        switch self {
        case .destinationTag(let stringTag):
            return UInt32(stringTag)
        }
    }
}
