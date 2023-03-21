//
//  FeeType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum FeeType {
    case single(fee: Fee)
    case multiple(low: Fee, normal: Fee, priority: Fee)
    
    init(fees: [Amount]) throws {
        try self.init(fees: fees.map { Fee($0) })
    }

    init(fees: [Fee]) throws {
        switch fees.count {
        case 1: // User hasn't a choice
            self = .single(fee: fees[0])
        case 3: // User has a choice of 3 option
            self = .multiple(low: fees[0], normal: fees[1], priority: fees[2])
        default:
            assertionFailure("Fee can't be created")
            throw BlockchainSdkError.failedToLoadFee
        }
    }
}

// MARK: - Helpers

public extension FeeType {
    static func zero(blockchain: Blockchain) -> FeeType {
        .single(fee: Fee(.zeroCoin(for: blockchain)))
    }
    
    var asArray: [Amount] {
        switch self {
        case .multiple(let low, let normal, let priority):
            return [low.amount, normal.amount, priority.amount]
            
        case .single(let fee):
            return [fee.amount]
        }
    }
    
    var lowFeeModel: Fee? {
        switch self {
        case .multiple(let low, _, _):
            return low
        case .single(let fee):
            return fee
        }
    }
    
    var normalFeeModel: Fee? {
        switch self {
        case .multiple(_, let normal, _):
            return normal
        case .single(let fee):
            return fee
        }
    }
    
    var priorityFeeModel: Fee? {
        switch self {
        case .multiple(_, _, let priority):
            return priority
        case .single(let fee):
            return fee
        }
    }
    
    var lowFee: Amount? {
        lowFeeModel?.amount
    }
    
    var normalFee: Amount? {
        normalFeeModel?.amount
    }
    
    var priorityFee: Amount? {
        priorityFeeModel?.amount
    }
}

extension FeeType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .single(let fee):
            return "Single option: \(fee)"
        case .multiple(let low, let normal, let priority):
            return """
            Multiple options:
            low: \(low)
            normal: \(normal)
            priority: \(priority)
            """
        }
    }
}
