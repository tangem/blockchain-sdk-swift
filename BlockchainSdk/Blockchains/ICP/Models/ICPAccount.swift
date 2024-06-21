//
//  ICPAccount.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 21.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ICPAccount {
    public let principal: ICPPrincipal
    public var address: String { accountId.hexString }
    public let accountId: Data
    public let subAccountId: Data
    
    public init(principal: ICPPrincipal, subAccountId: Data) throws {
        self.principal = principal
        self.subAccountId = subAccountId
        self.accountId = try ICPCryptography.accountId(of: principal, subAccountId: subAccountId)
    }
        
    public static func mainAccount(of principal: ICPPrincipal) throws -> ICPAccount {
        return try ICPAccount(
            principal: principal,
            subAccountId: Data(repeating: 0, count: 32)
        )
    }
}
