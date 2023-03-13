//
//  KaspaTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTarget: TargetType {
    let request: Request
    let baseURL: URL
    
    var path: String {
        switch request {
        case .balance(let address):
            return "/addresses/\(address)/balance"
        }
    }
    
    var method: Moya.Method {
        .get
    }
    
    var task: Moya.Task {
        .requestPlain
    }
    
    var headers: [String : String]? {
        nil
    }
}

extension KaspaTarget {
    enum Request {
        case balance(address: String)
    }
}
