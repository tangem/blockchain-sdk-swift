//
//  VeChainTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

// TODO: Andrey Fedorov - Add actual implementation (IOS-5239)
struct VeChainTarget {
    let baseURL: URL
    let target: Target
}

// MARK: - Auxiliary types

extension VeChainTarget {
    enum Target {}
}

// MARK: - TargetType protocol conformance

extension VeChainTarget: TargetType {
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Moya.Task {
        return .requestPlain
    }
    
    var headers: [String: String]? {
        return nil
    }
}
