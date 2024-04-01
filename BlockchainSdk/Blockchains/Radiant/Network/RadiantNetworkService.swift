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
            scripthash = try RadiantAddressUtils().prepareWallet(address: address)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
        
        return electrumProvider
            .getAddressInfo(identifier: .scriptHash(scripthash))
            .map { info in
                RadiantAddressInfo(balance: info.balance, outputs: info.outputs)
            }
            .eraseToAnyPublisher()
    }
    
    func estimatedFee() -> AnyPublisher<Decimal, Error> {
        electrumProvider
            .estimateFee()
    }
    
    func sendTransaction(data: Data) -> AnyPublisher<String, Error> {
        electrumProvider
            .send(transactionHex: data.hexString)
    }
}
