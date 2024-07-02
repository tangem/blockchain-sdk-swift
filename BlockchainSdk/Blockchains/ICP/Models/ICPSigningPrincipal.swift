//
//  ICPSigningPrincipal.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ICPSigningPrincipal {
    var principal: ICPPrincipal { get }
    var rawPublicKey: Data { get }
    
    /// All implementations of this method must ultimately call `ICPCryptography.ellipticSign` with the appropriate private key and return the result
    func sign(_ message: Data, domain: ICPDomainSeparator) async throws -> Data
}
