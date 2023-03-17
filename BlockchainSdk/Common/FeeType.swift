//
//  FeeType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeParameters {}

public enum FeeType {
    case single(fee: FeeModel)
    case multiple(low: FeeModel, normal: FeeModel, priority: FeeModel)
    
    public init(fees: [Amount]) throws {
        switch fees.count {
            /// User hasn't a choice
        case 1:
            self = .single(fee: FeeModel(fees[0]))
            /// User has a choice of 3 option
        case 3:
            self = .multiple(low: FeeModel(fees[0]), normal: FeeModel(fees[1]), priority: FeeModel(fees[2]))
        default:
            assertionFailure("FeeType can't be created")
            throw BlockchainSdkError.failedToLoadFee
        }
    }

    public init(fees: [FeeModel]) throws {
        switch fees.count {
        /// User hasn't a choice
        case 1:
            self = .single(fee: fees[0])
        /// User has a choice of 3 option
        case 3:
            self = .multiple(low: fees[0], normal: fees[1], priority: fees[2])
        default:
            assertionFailure("FeeType can't be created")
            throw BlockchainSdkError.failedToLoadFee
        }
    }
}

// MARK: - Helpers

public extension FeeType {
    static func zero(blockchain: Blockchain) -> FeeType {
        .single(fee: FeeModel(.zeroCoin(for: blockchain)))
    }
    
    var asArray: [Amount] {
        switch self {
        case .multiple(let low, let normal, let priority):
            return [low.fee, normal.fee, priority.fee]
            
        case .single(let fee):
            return [fee.fee]
        }
    }
    
    var lowFeeModel: FeeModel? {
        if case .multiple(let fee, _, _) = self {
            return fee
        }

        return nil
    }
    
    var normalFeeModel: FeeModel? {
        if case .multiple(_, let normal, _) = self {
            return normal
        }

        return nil
    }
    
    var priorityFeeModel: FeeModel? {
        if case .multiple(_, _, let priority) = self {
            return priority
        }

        return nil
    }
    
    var lowFee: Amount? {
        lowFeeModel?.fee
    }
    
    var normalFee: Amount? {
        normalFeeModel?.fee
    }
    
    var priorityFee: Amount? {
        priorityFeeModel?.fee
    }
}

// MARK: - FeeType

public extension FeeType {
    struct FeeModel {
        let fee: Amount
        let parameters: FeeParameters?
        
        init(_ fee: Amount, parameters: FeeParameters? = nil) {
            self.fee = fee
            self.parameters = parameters
        }
    }
}
