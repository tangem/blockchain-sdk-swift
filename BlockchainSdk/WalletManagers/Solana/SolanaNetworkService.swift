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
            .tryMap { [weak self] in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return self.mapInfo(mainAccountInfo: $0, tokenAccountsInfo: $1)
            }
            .eraseToAnyPublisher()
    }
    
    func sendSol(amount: UInt64, destinationAddress: String, signer: SolanaTransactionSigner) -> AnyPublisher<Void, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.action.sendSOL(
                to: destinationAddress,
                amount: amount,
                allowUnfundedRecipient: true,
                signer: signer
            ) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success:
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendSplToken(amount: UInt64, sourceTokenAddress: String, destinationAddress: String, token: Token, signer: SolanaTransactionSigner) -> AnyPublisher<Void, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.action.sendSPLTokens(
                mintAddress: token.contractAddress,
                decimals: Decimals(token.decimalCount),
                from: sourceTokenAddress,
                to: destinationAddress,
                amount: amount,
                allowUnfundedRecipient: true,
                signer: signer
            ) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success:
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func transactionFee(numberOfSignatures: Int) -> AnyPublisher<Decimal, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.api.getFees(commitment: nil) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let fee):
                    guard let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature else {
                        promise(.failure(BlockchainSdkError.failedToLoadFee))
                        return
                    }
                    
                    let totalFee = Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / blockchain.decimalValue

                    promise(.success(totalFee))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // This fee is deducted from the transaction amount itself (!)
    func mainAccountCreationFee() -> AnyPublisher<Decimal, Error> {
        // https://docs.solana.com/developing/programming-model/accounts#calculation-of-rent
        let minimumAccountSizeInBytes = Decimal(128)
        let numberOfEpochs = Decimal(1)
        let rentInLamportPerByteEpoch = Decimal(19.055441478439427)
        let lamportsInSol = blockchain.decimalValue
        
        let rent = minimumAccountSizeInBytes * numberOfEpochs * rentInLamportPerByteEpoch / lamportsInSol
        let rentAmount = Amount(with: blockchain, value: rent)

        return Just(rent).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // This fee is deducted from the main SOL account
    func tokenAccountCreationFee() -> AnyPublisher<Decimal, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.action.getCreatingTokenAccountFee { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let feeInLamports):
                    let amount = Decimal(feeInLamports) / blockchain.decimalValue
                    promise(.success(amount))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func mainAccountBalance(accountId: String) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> {
        Future { [unowned self] promise in
            self.solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let info):
                    let lamports = info.lamports
                    let accountInfo = SolanaMainAccountInfoResponse(balance: lamports, accountExists: true)
                    promise(.success(accountInfo))
                }
            }
        }.tryCatch { (error: Error) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> in
            if let solanaError = error as? SolanaError {
                switch solanaError {
                case .nullValue:
                    let info = SolanaMainAccountInfoResponse(balance: 0, accountExists: false)
                    return Just(info)
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
            let programId = PublicKey.tokenProgramId.base58EncodedString
            let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")

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
    
    private func mapInfo(mainAccountInfo: SolanaMainAccountInfoResponse, tokenAccountsInfo: [TokenAccount<AccountInfoData>]) -> SolanaAccountInfoResponse {
        let balance = Decimal(mainAccountInfo.balance) / blockchain.decimalValue
        let accountExists = mainAccountInfo.accountExists

        let tokens: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard let info = $0.account.data.value?.parsed.info else { return nil }
            let address = $0.pubkey
            let mint = info.mint
            let amount = Decimal(info.tokenAmount.uiAmount)
            
            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount)
        }
        let tokensByMint = Dictionary(uniqueKeysWithValues: tokens.map { ($0.mint, $0) })
        
        return SolanaAccountInfoResponse(balance: balance, accountExists: accountExists, tokensByMint: tokensByMint)
    }
}
