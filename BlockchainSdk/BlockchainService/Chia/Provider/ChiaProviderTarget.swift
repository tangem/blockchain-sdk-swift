//
//  ChiaProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct ChiaProviderTarget: TargetType {
    
    public var baseURL: URL

    public var path: String
    
    public var method: Moya.Method
    
    public var task: Moya.Task
    
    public var headers: [String : String]?
    
    
}
