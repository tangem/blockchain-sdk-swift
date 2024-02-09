//
//  HederaError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum HederaError: Error {
    case accountDoesNotExist
    case unsupportedCurve(curveName: String)
}
