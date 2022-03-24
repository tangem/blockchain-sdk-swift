//
//  TronTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum TronTarget: TargetType {
    case getAccount(address: String, network: TronNetwork)
    
    var baseURL: URL {
        switch self {
        case .getAccount(_, let network):
            return network.url
        }
    }
    
    var path: String {
        switch self {
        case .getAccount:
            return "/wallet/getaccount"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        let requestData: Data?
        
        do {
            switch self {
            case .getAccount(let address, _):
                let request = TronGetAccountRequest(address: address, visible: true)
                requestData = try encoder.encode(request)
            }
        } catch {
            print("Failed to encode Tron request data:", error)
            return .requestPlain
        }

        return .requestData(requestData ?? Data())
    }
    
    var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }
}
