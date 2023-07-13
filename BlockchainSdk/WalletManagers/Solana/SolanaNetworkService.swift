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
    var host: String {
        hostProvider.host
    }
    
    private let solanaSdk: Solana
    private let blockchain: Blockchain
    private let hostProvider: HostProvider
    
    init(solanaSdk: Solana, blockchain: Blockchain, hostProvider: HostProvider) {
        self.solanaSdk = solanaSdk
        self.blockchain = blockchain
        self.hostProvider = hostProvider
    }
    
    func getInfo(accountId: String, transactionIDs: [String]) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        Publishers.Zip3(
            mainAccountInfo(accountId: accountId),
            tokenAccountsInfo(accountId: accountId),
            confirmedTransactions(among: transactionIDs)
        )
            .tryMap { [weak self] mainAccount, tokenAccounts, confirmedTransactionIDs in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return self.mapInfo(mainAccountInfo: mainAccount, tokenAccountsInfo: tokenAccounts, confirmedTransactionIDs: confirmedTransactionIDs)
            }
            .eraseToAnyPublisher()
    }
    
    func sendSol(amount: UInt64, destinationAddress: String, signer: SolanaTransactionSigner) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.action.sendSOL(
            to: destinationAddress,
            amount: amount,
            allowUnfundedRecipient: true,
            signer: signer
        )
            .retry(1)
            .eraseToAnyPublisher()
    }
    
    func sendSplToken(amount: UInt64, sourceTokenAddress: String, destinationAddress: String, token: Token, signer: SolanaTransactionSigner) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.action.sendSPLTokens(
            mintAddress: token.contractAddress,
            decimals: Decimals(token.decimalCount),
            from: sourceTokenAddress,
            to: destinationAddress,
            amount: amount,
            allowUnfundedRecipient: true,
            signer: signer
        )
            .retry(1)
            .eraseToAnyPublisher()
    }
    
    func transactionFee(numberOfSignatures: Int) -> AnyPublisher<Decimal, Error> {
        solanaSdk.api.getFees(commitment: nil)
            .retry(1)
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                guard let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                return Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / self.blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }
    
    // This fee is deducted from the transaction amount itself (!)
    func mainAccountCreationFee() -> AnyPublisher<Decimal, Error> {
        accountRentFeePerEpoch()
    }
    
    func accountRentFeePerEpoch() -> AnyPublisher<Decimal, Error> {
        // https://docs.solana.com/developing/programming-model/accounts#calculation-of-rent
        let minimumAccountSizeInBytes = Decimal(128)
        let numberOfEpochs = Decimal(1)
        
        let rentInLamportPerByteEpoch: Decimal
        if blockchain.isTestnet {
            // Solana Testnet uses the same value as Mainnet.
            // The following value is for DEVNET. It is not mentioned in the docs and was obtained empirically.
            rentInLamportPerByteEpoch = Decimal(0.359375)
        } else {
            rentInLamportPerByteEpoch = Decimal(19.055441478439427)
        }
        let lamportsInSol = blockchain.decimalValue
        
        let rent = minimumAccountSizeInBytes * numberOfEpochs * rentInLamportPerByteEpoch / lamportsInSol
        
        return Just(rent).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // This fee is deducted from the main SOL account
    func tokenAccountCreationFee() -> AnyPublisher<Decimal, Error> {
        solanaSdk.action.getCreatingTokenAccountFee()
            .retry(1)
            .tryMap { [weak self] feeInLamports in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return Decimal(feeInLamports) / self.blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }
    
    func minimalBalanceForRentExemption() -> AnyPublisher<Decimal, Error> {
        // The accounts metadata size (128) is already factored in
        solanaSdk.api.getMinimumBalanceForRentExemption(dataLength: 0)
            .retry(1)
            .tryMap { [weak self] balanceInLamports in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return Decimal(balanceInLamports) / self.blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }
    
    private func mainAccountInfo(accountId: String) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> {
        solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self)
            .retry(1)
            .tryMap { info in
                let lamports = info.lamports
                let accountInfo = SolanaMainAccountInfoResponse(balance: lamports, accountExists: true)
                return accountInfo
            }
            .tryCatch { (error: Error) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> in
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
        let programId = PublicKey.tokenProgramId.base58EncodedString
        let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")
        
        return solanaSdk.api.getTokenAccountsByOwner(pubkey: accountId, programId: programId, configs: configs)
            .retry(1)
            .eraseToAnyPublisher()
    }
    
    private func confirmedTransactions(among transactionIDs: [String]) -> AnyPublisher<[String], Error> {
        guard !transactionIDs.isEmpty else {
            return .justWithError(output: [])
        }
        
        return solanaSdk.api.getSignatureStatuses(pubkeys: transactionIDs)
            .retry(1)
            .map { statuses in
                zip(transactionIDs, statuses)
                    .filter {
                        guard let status = $0.1 else { return true }
                        return status.confirmations == nil
                    }
                    .map {
                        $0.0
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func mapInfo(
        mainAccountInfo: SolanaMainAccountInfoResponse,
        tokenAccountsInfo: [TokenAccount<AccountInfoData>],
        confirmedTransactionIDs: [String]
    ) -> SolanaAccountInfoResponse {
        let balance = (Decimal(mainAccountInfo.balance) / blockchain.decimalValue).rounded(blockchain: blockchain)
        let accountExists = mainAccountInfo.accountExists
        
        let tokens: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard let info = $0.account.data.value?.parsed.info else { return nil }
            let address = $0.pubkey
            let mint = info.mint
            let amount = Decimal(info.tokenAmount.uiAmount).rounded(scale: Int(info.tokenAmount.decimals))
            
            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount)
        }
        
        let tokenPairs = tokens.map { ($0.mint, $0) }
        let tokensByMint = Dictionary(tokenPairs) { token1, _ in
            return token1
        }
        
        return SolanaAccountInfoResponse(balance: balance, accountExists: accountExists, tokensByMint: tokensByMint, confirmedTransactionIDs: confirmedTransactionIDs)
    }
}
