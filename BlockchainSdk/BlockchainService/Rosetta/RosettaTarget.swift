//
//  RosettaTarget.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum RosettaUrl {
    case getBlockRosetta(apiKey: String)
    case tangemRosetta
    
    var url: String {
        switch self {
        case .getBlockRosetta(let apiKey):
            return "https://ada.getblock.io/mainnet/\(apiKey)"
        case .tangemRosetta:
            return "https://ada.tangem.com"
        }
    }
}

enum RosettaTarget: TargetType {
    case address(baseUrl: RosettaUrl, addressBody: RosettaAddressBody)
    case submitTransaction(baseUrl: RosettaUrl, submitBody: RosettaSubmitBody)
    case coins(baseUrl: RosettaUrl, addressBody: RosettaAddressBody)
    
    var baseURL: URL {
        switch self {
        case .address(let url, _), .submitTransaction(let url, _), .coins(let url, _):
            return URL(string: url.url)!
        }
    }
    
    var path: String {
        switch self {
        case .address:
            return "/account/balance"
        case .submitTransaction:
            return "/construction/submit"
        case .coins:
            return "/account/coins"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .submitTransaction, .coins:
            return .post
        }
    }
    
    var sampleData: Data {
        Data()
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        switch self {
        case .address(_, let body), .coins(_, let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        case .submitTransaction(_, let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}
