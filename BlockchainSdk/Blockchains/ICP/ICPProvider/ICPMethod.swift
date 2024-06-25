//
//  ICPMethod.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftCBOR

public struct ICPMethod {
    let canister: ICPPrincipal
    let methodName: String
    let args: CandidValue?
}

public enum ICPRequest {
    case call(ICPMethod)
    case query(ICPMethod)
    case readState(paths: [ICPStateTreePath])
}
