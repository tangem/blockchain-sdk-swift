//
//  OptimismWalletManager.swift
//  Alamofire
//
//  Created by Pavel Grechikhin on 01.10.2022.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya
import web3swift


fileprivate let l1FeeABI: String =
        """
    [{"inputs":[{"internalType":"address","name":"_owner","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"DecimalsUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"GasPriceUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"L1BaseFeeUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"OverheadUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"ScalarUpdated","type":"event"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gasPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"getL1Fee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"getL1GasUsed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"l1BaseFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"overhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"scalar","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_decimals","type":"uint256"}],"name":"setDecimals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_gasPrice","type":"uint256"}],"name":"setGasPrice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_baseFee","type":"uint256"}],"name":"setL1BaseFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_overhead","type":"uint256"}],"name":"setOverhead","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_scalar","type":"uint256"}],"name":"setScalar","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
    """

public enum OPTError: Error, LocalizedError, DetailedError {
    case failedToParseTxCount
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case failedToParseGasLimit
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseTxCount:
            return "eth_tx_count_parse_error".localized
        case .failedToParseBalance:
            return "eth_balance_parse_error".localized
        case .failedToParseGasLimit: //TODO: refactor
            return "failedToParseGasLimit"
        case .unsupportedFeature:
            return "unsupportedFeature"
        }
    }
    
    public var detailedDescription: String? {
        switch self {
        case .failedToParseBalance(let value, let address, let decimals):
            return "value:\(value), address:\(address), decimals:\(decimals)"
        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
public protocol OptimismGasLoader: AnyObject {
    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(amount: Amount, destination: String) -> AnyPublisher<BigUInt, Error>
}

public protocol OptimismTransactionSigner: AnyObject {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error>
}

class OptimismWalletManager: BaseManager, WalletManager {
    var txBuilder: EthereumTransactionBuilder!
    var networkService: EthereumNetworkService!
    
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    var currentHost: String { networkService.host }
    
    private var gasLimit: BigUInt? = nil
    private var findTokensSubscription: AnyCancellable? = nil
    private let l1FeeContractMethodName: String = "getL1Fee"
    
    private var optimismFeeAddress: String {
        return EthereumAddress("0x420000000000000000000000000000000000000F")!.address
    }
    
    private var rpcURL: URL {
        return wallet.blockchain.getJsonRpcURLs(infuraProjectId: "613a0b14833145968b1f656240c7d245")![0]
    }
    
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
        txCount = response.txCount
        pendingTxCount = response.pendingTxCount
        
        if !response.pendingTxs.isEmpty {
            wallet.transactions.removeAll()
            response.pendingTxs.forEach {
                wallet.addPendingTransaction($0)
            }
        } else if txCount == pendingTxCount {
            for  index in wallet.transactions.indices {
                wallet.transactions[index].status = .confirmed
            }
        } else {
            if wallet.transactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        }
    }
    
    private func formatDestinationInfo(for destination: String, amount: Amount) -> (to: String, value: String?, data: String?) {
        var to = destination
        var value: String? = nil
        var data: String? = nil
        
        if amount.type == .coin,
           let amountValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: amount.decimals)
        {
            value = "0x" + String(amountValue, radix: 16)
        }
        
        if let token = amount.type.token, let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
            to = token.contractAddress
            data = "0x" + erc20Data.hexString
        }
        
        return (to, value, data)
    }
}

extension OptimismWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        sign(transaction, signer: signer)
            .flatMap {[weak self] tx -> AnyPublisher<Void, Error> in
                self?.networkService.send(transaction: tx).tryMap {[weak self] sendResponse in
                    guard let self = self else { throw WalletError.empty }
                    
                    var tx = transaction
                    tx.hash = sendResponse
                    self.wallet.add(transaction: tx)
                }
                .mapError { SendTxError(error: $0, tx: tx) }
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let destinationInfo = formatDestinationInfo(for: destination, amount: amount)
        let l2Fee = networkService.getFee(to: destinationInfo.to,
                                          from: wallet.address,
                                          value: destinationInfo.value,
                                          data: destinationInfo.data)
        let tx = txBuilder.buildForSign(transaction: Transaction.dummyTx(blockchain: wallet.blockchain,
                                                                         type: amount.type,
                                                                         destinationAddress: destination), nonce: 1, gasLimit: BigUInt(1))
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let l1Fee = getL1Fee(amount: amount, destination: destinationInfo.to, transactionHash: byteArray.toHexString())
        
        return Publishers.CombineLatest(l2Fee, l1Fee)
            .tryMap { (l1FeeResponse, l2FeeResponse) in
                guard l1FeeResponse.fees.count == 3 else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                self.gasLimit = l1FeeResponse.gasLimit
                
                let minAmount = Amount(with: self.wallet.blockchain, value: l1FeeResponse.fees[0] + l2FeeResponse.value)
                let normalAmount = Amount(with: self.wallet.blockchain, value: l1FeeResponse.fees[1] + l2FeeResponse.value)
                let maxAmount = Amount(with: self.wallet.blockchain, value: l1FeeResponse.fees[2] + l2FeeResponse.value)
                return [minAmount, normalAmount, maxAmount, l2FeeResponse]
            }
            .eraseToAnyPublisher()
    }
    
    private func getL1Fee(amount: Amount, destination: String, transactionHash: String) -> AnyPublisher<Amount, Error> {
        return Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }
                let contractInteractor = ContractInteractor(address: self.optimismFeeAddress, abi: l1FeeABI, rpcURL: self.rpcURL)
                let params = [transactionHash] as! [AnyObject]
                contractInteractor.read(method: self.l1FeeContractMethodName, parameters: params) { result in
                    switch result {
                    case .success(let response):
                        if let bigUIntFee = BigUInt("\(response)"),
                           let fee = Web3.Utils.formatToEthereumUnits(bigUIntFee, toUnits: .eth, decimals: 18, decimalSeparator: ".", fallbackToScientific: false),
                           let decimalFee = Decimal(fee) {
                            let amount = Amount(with: self.wallet.blockchain, value: decimalFee)
                            promise(.success(amount))
                        } else {
                            promise(.failure(BlockchainSdkError.failedToLoadFee))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension OptimismWalletManager: EthereumTransactionSigner {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction,
                                                     nonce: txCount,
                                                     gasLimit: gasLimit) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hash: txForSign.hash,
                           walletPublicKey: self.wallet.publicKey)
        .tryMap {[weak self] signature -> String in
            guard let self = self else { throw WalletError.empty }
            
            guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signature) else {
                throw WalletError.failedToBuildTx
            }
            
            return "0x\(tx.toHexString())"
        }
        .eraseToAnyPublisher()
    }
}

extension OptimismWalletManager: EthereumGasLoader {
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }
    
    func getGasLimit(amount: Amount, destination: String) -> AnyPublisher<BigUInt, Error> {
        let destInfo = formatDestinationInfo(for: destination, amount: amount)
        
        return networkService
            .getGasLimit(to: destInfo.to, from: wallet.address, value: destInfo.value, data: destInfo.data)
            .eraseToAnyPublisher()
    }
}

extension OptimismWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(address: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

extension OptimismWalletManager: ThenProcessable { }

extension OptimismWalletManager: TokenFinder {
    func findErc20Tokens(knownTokens: [Token], completion: @escaping (Result<Bool, Error>)-> Void) {
        findTokensSubscription?.cancel()
        findTokensSubscription = networkService
            .findErc20Tokens(address: wallet.address)
            .sink(receiveCompletion: { subscriptionCompletion in
                if case let .failure(error) = subscriptionCompletion {
                    completion(.failure(error))
                    return
                }
            }, receiveValue: {[unowned self] blockchairTokens in
                if blockchairTokens.isEmpty {
                    completion(.success(false))
                    return
                }
                
                var tokensAdded = false
                blockchairTokens.forEach { blockchairToken in
                    let foundToken = Token(blockchairToken, blockchain: self.wallet.blockchain)
                    if !self.cardTokens.contains(foundToken) {
                        let token: Token = knownTokens.first(where: { $0 == foundToken }) ?? foundToken
                        self.cardTokens.append(token)
                        let balanceValue = Decimal(blockchairToken.balance) ?? 0
                        let balanceWeiValue = balanceValue / pow(Decimal(10), blockchairToken.decimals)
                        self.wallet.add(tokenValue: balanceWeiValue, for: token)
                        tokensAdded = true
                    }
                }
                
                completion(.success(tokensAdded))
            })
    }
}
