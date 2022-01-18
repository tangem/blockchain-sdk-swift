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
    private func mapInfo(mainAccountInfo: BufferInfo<AccountInfo>, tokenAccountsInfo: [TokenAccount<AccountInfoData>]) -> SolanaAccountInfoResponse {
        let tokens: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard let info = $0.account.data.value?.parsed.info else { return nil }

            let amount = Decimal(info.tokenAmount.uiAmount)

            let token = Token(
                name: "",
                symbol: "",
                contractAddress: info.mint,
                decimalCount: Int(info.tokenAmount.decimals),
                blockchain: self.blockchain
            )
            
            return SolanaTokenAccountInfoResponse(balance: amount, token: token)
        }
        
        let blockchain = Blockchain.solana(testnet: false)
        let balance = Decimal(mainAccountInfo.lamports) / blockchain.decimalValue
        
        return SolanaAccountInfoResponse(balance: balance, tokens: tokens)
    }
}
