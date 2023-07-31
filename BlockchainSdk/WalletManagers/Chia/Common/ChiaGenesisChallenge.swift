//
//  ChiaGenesisChalenge.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ChiaGenesisChallenge {
    private static let genesisChallengeMainnet = "ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb"
    private static let genesisChallengeTestnet = "ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2"
    
    static func genesisChallenge(isTestnet: Bool) -> String {
        return isTestnet ? genesisChallengeTestnet : genesisChallengeMainnet
    }
}
