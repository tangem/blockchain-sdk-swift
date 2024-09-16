//
// SuiBalanceFetcher.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 16.09.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine


public class SuiBalanceFetcher {
    
    public typealias BuildRequestPublisher = (_ address: String, _ coin: String, _ cursor: String?) -> AnyPublisher<SuiGetCoins, Error>
    
    private var cancellable = Set<AnyCancellable>()
    
    private var coins = Set<SuiGetCoins.Coin>()
    
    private var subject = PassthroughSubject<[SuiGetCoins.Coin], Error>()
    private var requestPublisher: BuildRequestPublisher?
    
    public var publisher: AnyPublisher<[SuiGetCoins.Coin], Error> {
        subject.eraseToAnyPublisher()
    }
    
    public func requestPublisher(with:  @escaping BuildRequestPublisher) -> Self {
        self.requestPublisher = with
        return self
    }
    
    public func fetchBalanceRequestPublisher(address: String, coin: String, cursor: String?) -> AnyPublisher<[SuiGetCoins.Coin], Error> {
        cancel()
        clear()
        
        guard let `requestPublisher` = requestPublisher?(address, coin, cursor) else {
            return .anyFail(error: WalletError.empty)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.load(address: address, coin: coin, cursor: cursor, requestPublisher: requestPublisher)
        }
        
        return publisher
    }
    
    private func load(address: String, coin: String, cursor: String?, requestPublisher: AnyPublisher<SuiGetCoins, Error>) {
        requestPublisher
            .sink { [weak self] completionSubscriptions in
                if case .failure = completionSubscriptions {
                    self?.subject.send(completion: completionSubscriptions)
                }
            } receiveValue: { [weak self] response in
                
                guard let self else {
                    return
                }
                
                coins.formUnion(response.data)
                
                if !response.hasNextPage {
                    guard let nextPublisher = self.requestPublisher?(address, coin, response.nextCursor) else {
                        self.subject.send(completion: .failure(WalletError.empty))
                        return
                    }
                    
                    self.load(address: address, coin: coin, cursor: response.nextCursor, requestPublisher: nextPublisher)
                } else {
                    self.subject.send(self.coins.asArray)
                    self.clear()
                }
            }
            .store(in: &cancellable)
    }
    
    func cancel() {
        cancellable.forEach({ $0.cancel() })
        cancellable.removeAll()
    }
    
    func clear() {
        coins.removeAll()
    }
    
}
