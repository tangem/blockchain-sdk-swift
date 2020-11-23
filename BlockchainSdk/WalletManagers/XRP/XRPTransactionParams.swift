//
//  XRPTransactionParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 23.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum XRPTransactionParams: TransactionParams {
     case destinationTag(value: String)
}
