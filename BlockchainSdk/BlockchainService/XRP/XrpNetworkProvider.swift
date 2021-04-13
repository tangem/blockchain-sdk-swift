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

class XRPNetworkProvider: XRPNetworkServiceType {
    let baseUrl: XrpUrl
    let provider = MoyaProvider<XrpTarget>()
    
    init(baseUrl: XrpUrl) {
        self.baseUrl = baseUrl
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        return request(.fee(url: baseUrl))
            .tryMap { xrpResponse -> XRPFeeResponse in
                guard let minFee = xrpResponse.result?.drops?.minimum_fee,
                      let normalFee = xrpResponse.result?.drops?.open_ledger_fee,
                      let maxFee = xrpResponse.result?.drops?.median_fee,
                      let minFeeDecimal = Decimal(string: minFee),
                      let normalFeeDecimal = Decimal(string: normalFee),
                      let maxFeeDecimal = Decimal(string: maxFee) else {
                    throw WalletError.failedToGetFee
                }
                
                return XRPFeeResponse(min: minFeeDecimal, normal: normalFeeDecimal, max: maxFeeDecimal)
            }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(blob: String) -> AnyPublisher<Bool, Error> {
        return request(.submit(tx: blob, url: baseUrl))
            .tryMap { xrpResponse -> Bool in
                guard let code = xrpResponse.result?.engine_result_code else {
                    throw WalletError.failedToSendTx
                }
                
                if code != 0 {
                    let message = xrpResponse.result?.engine_result_message ?? WalletError.failedToSendTx.localizedDescription
                    if message != "Held until escalated fee drops." { //TODO: find the error code
                        throw message
                    }
                }
                
                return true
            }
            .eraseToAnyPublisher()
    }
    
    func getUnconfirmed(account: String) -> AnyPublisher<Decimal, Error> {
        return request(.unconfirmed(account: account, url: baseUrl))
            .tryMap { xrpResponse -> Decimal in
                try self.assertAccountCreated(xrpResponse)
                
                guard let unconfirmedBalanceString = xrpResponse.result?.account_data?.balance,
                      let unconfirmedBalance = Decimal(unconfirmedBalanceString) else {
                    throw XRPError.failedLoadUnconfirmed
                }
                
                return unconfirmedBalance
            }
            .eraseToAnyPublisher()
    }
    
    func getReserve() -> AnyPublisher<Decimal, Error> {
        return request(.reserve(url: baseUrl))
            .tryMap{ xrpResponse -> Decimal in
                try self.assertAccountCreated(xrpResponse)
                
                guard let reserveBase = xrpResponse.result?.state?.validated_ledger?.reserve_base else {
                    throw XRPError.failedLoadReserve
                }
                
                return Decimal(reserveBase)
            }
            .eraseToAnyPublisher()
    }
    
    func getAccountInfo(account: String) -> AnyPublisher<(balance: Decimal, sequence: Int), Error> {
        return request(.accountInfo(account: account, url: baseUrl))
            .tryMap{[unowned self] xrpResponse in
                try self.assertAccountCreated(xrpResponse)
                
                guard let accountResponse = xrpResponse.result?.account_data,
                      let balanceString = accountResponse.balance,
                      let sequence = accountResponse.sequence,
                      let balance = Decimal(balanceString) else {
                    throw XRPError.failedLoadInfo
                }
                
                return (balance: balance, sequence: sequence)
            }
            .eraseToAnyPublisher()
    }
    
    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error> {
        return Publishers.Zip3(getUnconfirmed(account: account),
                               getReserve(),
                               getAccountInfo(account: account))
            .map { (unconfirmed, reserve, info) -> XrpInfoResponse in
                return XrpInfoResponse(balance: info.balance,
                                       sequence: info.sequence,
                                       unconfirmedBalance: unconfirmed,
                                       reserve: reserve)
                
            }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        return request(.accountInfo(account: account, url: baseUrl))
            .map {[unowned self] xrpResponse -> Bool in
                do {
                    try self.assertAccountCreated(xrpResponse)
                    return true
                } catch {
                    return false
                }
            }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    private func assertAccountCreated(_ repsonse: XrpResponse) throws {
        if let code = repsonse.result?.error_code, code == 19 {
            throw WalletError.noAccount(message: "no_account_xrp".localized)
        }
    }
    
    private func request(_ target: XrpTarget) -> AnyPublisher<XrpResponse, MoyaError> {
        provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(XrpResponse.self)
    }
}
