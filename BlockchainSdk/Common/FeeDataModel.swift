//
//  FeeDataModel.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeParameters {}

public struct FeeDataModel {
    public let feeType: FeeType
    public var additionalParameters: FeeParameters?
  
    public init(feeType: FeeDataModel.FeeType) {
        self.feeType = feeType
    }
    
    init(fees: [Amount]) throws {
        switch fees.count {
        // user have not a choise
        case 1:
            self.feeType = .single(fee: fees[0])
        // fee have a choise
        case 3:
            self.feeType = .multiple(low: fees[0], normal: fees[1], priority: fees[2])
        default:
            assertionFailure("FeeDataModel can't be created")
            throw BlockchainSdkError.failedToLoadFee
        }
    }
}

// MARK: - Helpers

public extension FeeDataModel {
    static func zero(blockchain: Blockchain) -> FeeDataModel {
        FeeDataModel(feeType: .single(fee: .zeroCoin(for: blockchain)))
    }
    
    var asArray: [Amount] {
        switch feeType {
        case .multiple(let low, let normal, let priority):
            return [low, normal, priority]
            
        case .single(let fee):
            return [fee]
        }
    }
    
    var lowFee: Amount? {
        if case .multiple(let fee, _, _) = feeType {
            return fee
        }

        return nil
    }
    
    var normalFee: Amount? {
        if case .multiple(_, let normal, _) = feeType {
            return normal
        }

        return nil
    }
    
    var priorityFee: Amount? {
        if case .multiple(_, _, let priority) = feeType {
            return priority
        }

        return nil
    }
}

// MARK: - FeeType

public extension FeeDataModel {
    enum FeeType: CustomStringConvertible {
        case single(fee: Amount)
        case multiple(low: Amount, normal: Amount, priority: Amount)
    }
}

extension FeeDataModel: CustomStringConvertible {
    public var description: String {
        "feeType \(feeType.description)\nadditionalParameters\(String(describing: additionalParameters))"
    }
}
