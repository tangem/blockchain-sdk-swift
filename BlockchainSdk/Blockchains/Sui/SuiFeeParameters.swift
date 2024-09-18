//
// SuiFeeParameters.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 05.09.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiFeeParameters: FeeParameters {
    public let gasPrice: Decimal
    public let gasBudget: Decimal
}
