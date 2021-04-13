//
//  XRPNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

protocol XRPNetworkServiceType {
    func getFee() -> AnyPublisher<XRPFeeResponse, Error>
    func send(blob: String) -> AnyPublisher<Bool, Error>
    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error>
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error>
}

class XRPNetworkService: MultiNetworkProvider<XRPNetworkProvider>, XRPNetworkServiceType {
    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error> {
        providerPublisher { provider in
            provider.getInfo(account: account)
        }
    }
    
    func send(blob: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.send(blob: blob)
        }
    }
    
    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        providerPublisher { provider in
            provider.getFee()
        }
    }
    
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.checkAccountCreated(account: account)
        }
    }
}
