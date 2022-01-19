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
    private let solanaSdk: Solana
    private let blockchain: Blockchain
    
    init(solanaSdk: Solana, blockchain: Blockchain) {
        self.solanaSdk = solanaSdk
        self.blockchain = blockchain
    }
    
    func accountInfo(accountId: String) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        Publishers.Zip(mainAccountBalance(accountId: accountId), tokenAccountsInfo(accountId: accountId))
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
                        promise(.failure(SolanaWalletError.noFeeReturned))
                        return
                    }
                    
                    let totalFee = Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / blockchain.decimalValue

                    promise(.success(totalFee))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mainAccountBalance(accountId: String) -> AnyPublisher<Lamports, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let info):
                    let lamports = info.lamports
                    promise(.success(lamports))
                }
            }
        }.tryCatch { (error: Error) -> AnyPublisher<Lamports, Error> in
            if let solanaError = error as? SolanaError {
                switch solanaError {
                case .nullValue:
                    return Just(0)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                default:
                    break
                }
            }
            
            throw error
        }.eraseToAnyPublisher()
    }
    
    private func tokenAccountsInfo(accountId: String) -> AnyPublisher<[TokenAccount<AccountInfoData>], Error> {
        Future { [unowned self] promise in
            let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")
            let programId = PublicKey.tokenProgramId.base58EncodedString

            self.solanaSdk.api.getTokenAccountsByOwner(pubkey: accountId, programId: programId, configs: configs) {
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
    private func mapInfo(mainAccountBalance: Lamports, tokenAccountsInfo: [TokenAccount<AccountInfoData>]) -> SolanaAccountInfoResponse {
        let balance = Decimal(mainAccountBalance) / blockchain.decimalValue

        let tokens: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard let info = $0.account.data.value?.parsed.info else { return nil }
            let address = $0.pubkey
            let mint = info.mint
            let amount = Decimal(info.tokenAmount.uiAmount)
            
            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount)
        }
        let tokensByMint = Dictionary(uniqueKeysWithValues: tokens.map { ($0.mint, $0) })
        
        return SolanaAccountInfoResponse(balance: balance, tokensByMint: tokensByMint)
    }
}
