//
//  RavencoinProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct RavencoinProvider {
    
}
// https://ravencoin.network/api/addr/RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi

enum RavencoinTarget: TargetType {
    case addressInfo(_ address: String)
    
    var headers: [String : String]? { nil }
    var baseURL: URL { URL(string: "https://ravencoin.network/api/")! }
    
    var path: String {
        switch self {
        case let .addressInfo(address):
            return "addr/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .addressInfo:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .addressInfo:
            return .requestPlain
        }
    }
    
    
}
