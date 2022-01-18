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
class SolanaNetworkService {
    let solanaSdk: Solana
    
    init(solanaSdk: Solana) {
        self.solanaSdk = solanaSdk
    }
    
    func accountInfo(accountId: String) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        Publishers.Zip(mainAccountInfo(accountId: accountId), tokenAccountsInfo(accountId: accountId))
            .map(self.mapInfo)
            .eraseToAnyPublisher()
    }
    
    func fee(numberOfSignatures: Int) -> AnyPublisher<Decimal, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.api.getFees(commitment: nil) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let fee):
                    guard let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature else {
                        promise(.failure(SolanaError.noFeeReturned))
                        return
                    }
                    
                    let blockchain = Blockchain.solana(testnet: false)
                    let totalFee = Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / blockchain.decimalValue

                    promise(.success(totalFee))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mainAccountInfo(accountId: String) -> AnyPublisher<BufferInfo<AccountInfo>, Error> {
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
    
    private func tokenAccountsInfo(accountId: String) -> AnyPublisher<[TokenAccount<AccountInfoData>], Error> {
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

private extension SolanaNetworkService {
    private func mapInfo(mainAccountInfo: BufferInfo<AccountInfo>, tokenAccountsInfo: [TokenAccount<AccountInfoData>]) -> SolanaAccountInfoResponse {
        let tokens: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard let info = $0.account.data.value?.parsed.info else { return nil }
            let address = $0.pubkey
            let mint = info.mint
            let amount = Decimal(info.tokenAmount.uiAmount)
            
            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount)
        }
        
        let blockchain = Blockchain.solana(testnet: false)
        let balance = Decimal(mainAccountInfo.lamports) / blockchain.decimalValue
        
        return SolanaAccountInfoResponse(balance: balance, tokens: tokens)
    }
}
