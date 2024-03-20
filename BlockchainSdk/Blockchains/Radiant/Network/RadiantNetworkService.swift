//
//  RadiantNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RadiantNetworkService {
    let electrumProvider: ElectrumNetworkProvider
    
    init(electrumProvider: ElectrumNetworkProvider) {
        self.electrumProvider = electrumProvider
    }
}

extension RadiantNetworkService: HostProvider {
    var host: String {
        electrumProvider.host
    }
}

extension RadiantNetworkService {
    func getInfo(address: String) -> AnyPublisher<RadiantAddressInfo, Error> {
        let scripthash: String
        
        do {
            scripthash = try RadiantUtils().prepareWallet(address: address)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
        
        return electrumProvider
            .getAddressInfoWithScripts(identifier: .scripthash(scripthash))
            .map { info in
                let balance = info.balance
                
                let outputs: [BitcoinUnspentOutput] = info.outputs.compactMap { output -> BitcoinUnspentOutput? in
                    guard
                        let script = info.scripts.first(where: { $0.transactionHash == output.hash }),
                        let vout = script.outputs.first(where: { $0.scriptPubKey.addresses.contains(address) })
                    else {
                        return nil
                    }
                    
                    return .init(
                        transactionHash: output.hash,
                        outputIndex: output.position,
                        amount: output.value.uint64Value,
                        outputScript: vout.scriptPubKey.hex
                    )
                }
                
                return RadiantAddressInfo(balance: balance, outputs: outputs)
            }
            .eraseToAnyPublisher()
    }
    
    func estimatedFee() -> AnyPublisher<Decimal, Error> {
        electrumProvider
            .estimateFee()
    }
}
