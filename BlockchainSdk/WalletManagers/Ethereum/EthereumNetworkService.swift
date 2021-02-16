//
//  EthereumNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON
import web3swift
import BigInt

class EthereumNetworkService {
    private let network: EthereumNetwork
    private let provider = MoyaProvider<InfuraTarget>(plugins: [NetworkLoggerPlugin()])
    private let blockcypherProvider: BlockcypherProvider?
    private let canManageTokens: Bool
	
    init(network: EthereumNetwork, blockcypherProvider: BlockcypherProvider?, canManageTokens: Bool) {
        self.network = network
        self.blockcypherProvider = blockcypherProvider
        self.canManageTokens = canManageTokens
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestPublisher(.send(transaction: transaction, network: network))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] response throws -> String in
                if let hash = try? self.parseResult(response.data),
                    hash.count > 0 {
                    return hash
                }
                throw WalletError.failedToParseNetworkResponse
        }
        .eraseToAnyPublisher()
    }
    
    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumResponse, Error> {
        if !tokens.isEmpty {
            return tokenData(address: address, tokens: tokens)
                .map { return EthereumResponse(balance: $0.0, tokenBalances: $0.1, txCount: $0.2, pendingTxCount: $0.3) }
                .eraseToAnyPublisher()
        } else {
            return coinData(address: address)
                .map { return EthereumResponse(balance: $0.0, tokenBalances: [:], txCount: $0.1, pendingTxCount: $0.2) }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        let future = Future<BigUInt,Error> {[unowned self] promise in
            DispatchQueue.global().async {
                guard let web3Network = self.network.getWeb3Network() else {
                    promise(.failure(WalletError.failedToGetFee))
                    return
                }
                let provider = Web3HttpProvider(self.network.url, network: web3Network, keystoreManager: nil)!
                let web = web3(provider: provider)
                
                guard let gasPrice = try? web.eth.getGasPrice() else {
                    promise(.failure(WalletError.failedToGetFee))
                    return
                }
                
                promise(.success(gasPrice))
            }
        }
        return AnyPublisher(future)
    }
    
    func getGasLimit(to: String, from: String, data: String?) -> AnyPublisher<BigUInt, Error> {
        return provider
            .requestPublisher(.gasPrice(to: to, from: from, data: data, network: network))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] in try self.parseGas($0.data)}
            .eraseToAnyPublisher()
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] token -> AnyPublisher<(Token, Decimal), Error> in
                let tokenBalancePublisher = self.getTokenBalance(address, contractAddress: token.contractAddress, tokenDecimals: token.decimalCount)
                if self.canManageTokens {
                    return tokenBalancePublisher
                        .replaceError(with: -1)
                        .map { (token, $0) }
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return tokenBalancePublisher
                    .map { (token, $0) }
                    .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) {
                guard $1.1 >= 0 else { return }
                
                $0[$1.0] = $1.1
            }}
            .eraseToAnyPublisher()
    }
    
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        guard let blockcypherProvider = blockcypherProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
		return blockcypherProvider.getSignatureCount(address: address)
	}
    
	// MARK: - Private functions
    
    private func tokenData(address: String, tokens: [Token]) -> AnyPublisher<(Decimal,[Token:Decimal],Int,Int), Error> {
        return Publishers.Zip4(getBalance(address),
                               getTokensBalance(address, tokens: tokens),
                               getTxCount(address),
                               getPendingTxCount(address))
            .eraseToAnyPublisher()
    }
    
    private func coinData(address: String) -> AnyPublisher<(Decimal,Int,Int), Error> {
        return Publishers.Zip3(getBalance(address),
                               getTxCount(address),
                               getPendingTxCount(address))
            .eraseToAnyPublisher()
    }
    
    private func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .transactions(address: address, network: network))
    }
    
    private func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .pending(address: address, network: network))
    }
    
    private func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        return provider
            .requestPublisher(.balance(address: address, network: network))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] in try self.parseBalance($0.data)}
            .eraseToAnyPublisher()
    }
    
    private func getTokenBalance(_ address: String, contractAddress: String, tokenDecimals: Int) -> AnyPublisher<Decimal, Error> {
        return provider
            .requestPublisher(.tokenBalance(address: address, contractAddress: contractAddress, network: network ))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap{[unowned self] in try self.parseTokenBalance($0.data, tokenDecimals: tokenDecimals)}
            .eraseToAnyPublisher()
    }
    
    private func getTxCount(target: InfuraTarget) -> AnyPublisher<Int, Error> {
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] in try self.parseTxCount($0.data)}
            .eraseToAnyPublisher()
    }
    
    private func parseResult(_ data: Data) throws -> String {
        let balanceInfo = JSON(data)
        if let result = balanceInfo["result"].string {
            return result
        }
        
        throw WalletError.failedToParseNetworkResponse
    }
    
    private func parseGas(_ data: Data) throws -> BigUInt {
        let res = try parseResult(data)
        guard let count = BigUInt(res.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }
        
        return count
    }
    
    private func parseTxCount(_ data: Data) throws -> Int {
        let countString = try parseResult(data)
        guard let count = Int(countString.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseTxCount
        }
        
        return count
    }
    
    private func parseBalance(_ data: Data) throws -> Decimal {
        let quantity = (try parseResult(data)).removeHexPrefix()
        guard let balanceData = asciiHexToData(quantity),
              let balanceWei = dataToDecimal(balanceData) else {
                throw ETHError.failedToParseBalance
        }
        
        let balanceEth = balanceWei / Decimal(1000000000000000000)
        return balanceEth
    }
    
    private func parseTokenBalance(_ data: Data, tokenDecimals: Int) throws -> Decimal {
        let quantity = (try parseResult(data)).removeHexPrefix()
        guard let balanceData = asciiHexToData(quantity),
              let balanceWei = dataToDecimalToken(balanceData) else {
            throw ETHError.failedToParseTokenBalance
        }
        
        let balanceEth = balanceWei.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(tokenDecimals)))
        return balanceEth as Decimal
    }
}

struct EthereumResponse {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let txCount: Int
    let pendingTxCount: Int
}

//MARK: Bytes
fileprivate extension EthereumNetworkService {
    private func dataToDecimal(_ data: Data) -> Decimal? {
        if data.count > 8 {
            return nil
        }
        let temp = NSData(bytes: data.reversed(), length: data.count)

        let rawPointer = UnsafeRawPointer(temp.bytes)
        let pointer = rawPointer.assumingMemoryBound(to: UInt64.self)
        let value = pointer.pointee
        return NSDecimalNumber(value: value) as Decimal
    }
    
    private func dataToDecimalToken(_ data: Data) -> NSDecimalNumber? {
        let reversed = data.reversed()
        var number = NSDecimalNumber(value: 0)

        reversed.enumerated().forEach { (arg) in
            let (offset, value) = arg
            number = number.adding(NSDecimalNumber(value: value).multiplying(by: NSDecimalNumber(value: 256).raising(toPower: offset)))
        }

        return number
    }
    
    private func asciiHexToData(_ hexString: String) -> Data? {

        var trimmedString = hexString.trimmingCharacters(in: NSCharacterSet(charactersIn: "<> ") as CharacterSet).replacingOccurrences(of: " ", with: "")
        if trimmedString.count % 2 != 0 {
            trimmedString = "0" + trimmedString
        }

        guard isValidHex(trimmedString) else {
            return nil
        }
        
        var data = [UInt8]()
        var fromIndex = trimmedString.startIndex
        while let toIndex = trimmedString.index(fromIndex, offsetBy: 2, limitedBy: trimmedString.endIndex) {

            let byteString = String(trimmedString[fromIndex..<toIndex])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append(num)

            fromIndex = toIndex
        }

        return Data(data)
    }
    
    private func isValidHex(_ asciiHex: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: asciiHex, options: [], range: NSRange(location: 0, length: asciiHex.count))

        if found == nil || found?.range.location == NSNotFound || asciiHex.count % 2 != 0 {
            return false
        }

        return true
    }
}
