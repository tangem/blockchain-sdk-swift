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
    
    func estimatedFee() -> AnyPublisher<BitcoinFee, Error> {
        electrumProvider
            .estimateFee()
            .map { sourceFee in
                let targetFee = sourceFee > 0 ? sourceFee : Constants.defaultFeePer1000Bytes
                
                let minimal = targetFee
                let normal = targetFee * Constants.normalFeeMultiplier
                let priority = targetFee * Constants.priorityFeeMultiplier
                
                return BitcoinFee(
                    minimalSatoshiPerByte: minimal,
                    normalSatoshiPerByte: normal,
                    prioritySatoshiPerByte: priority
                )
            }
            .eraseToAnyPublisher()
    }
    
    func sendTransaction(data: Data) -> AnyPublisher<String, Error> {
        electrumProvider
            .send(transactionHex: data.hexString)
    }
}

extension RadiantNetworkService {
    enum Constants {
        static let defaultFeePer1000Bytes: Decimal = 0.00001
        static let normalFeeMultiplier: Decimal = 1.5
        static let priorityFeeMultiplier: Decimal = 2
    }
}
