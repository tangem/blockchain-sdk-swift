//
//  SolanaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 17.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Solana_Swift

@available(iOS 13.0, *)
public class SolanaNetworkService {
    let solanaSdk: Solana
    
    init(solanaSdk: Solana) {
        self.solanaSdk = solanaSdk
    }
    
//    public func accountInfo(accountId: String) -> AnyPublisher<Void, Error> {
//    
//    }
    
    public func mainAccountInfo(accountId: String) -> AnyPublisher<BufferInfo<AccountInfo>, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let info):
                    promise(.success(info))
                }
            }
        }.eraseToAnyPublisher()

    }
    
    public func tokenAccountsInfo(accountId: String) -> AnyPublisher<[TokenAccount<AccountInfoData>], Error> {
        let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")
        let programId = PublicKey.tokenProgramId.base58EncodedString
        
        return Future { [unowned self] promise in
            self.solanaSdk.api.getTokenAccountsByOwner(pubkey: accountId, mint: nil, programId: programId, configs: configs) {
                (result: Result<[TokenAccount<AccountInfoData>], Error>) in
                
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let tokens):
                    promise(.success(tokens))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
