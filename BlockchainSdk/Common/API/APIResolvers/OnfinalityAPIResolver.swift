//
//  OnfinalityAPIResolver.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 10.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnfinalityAPIResolver {
    let config: BlockchainSdkConfig
    
    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard
            case .bittensor = blockchain,
            let url = URL(string: "https://bittensor-finney.api.onfinality.io/rpc/")
        else {
            return nil
        }
        
        return .init(
            url: url,
            keyInfo: APIHeaderKeyInfo(
                headerName: Constants.bittensorOnfinalityApiKey,
                headerValue: config.bittensorOnfinalityKey
            )
        )
    }
}
