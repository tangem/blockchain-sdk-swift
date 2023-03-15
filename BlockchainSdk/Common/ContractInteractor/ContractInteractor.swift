//
//  ContractInteractor.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 30.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import web3swift

public class ContractInteractor<Contract: SmartContract> {
    private let contract: Contract
    private lazy var defaultOptions: TransactionOptions = .defaultOptions
    
    public init(contract: Contract) {
        self.contract = contract
    }
    
    public func read(method: Contract.MethodType) -> AnyPublisher<Any, Error> {
        return Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    return
                }
                
                self.read(method: method.name, parameters: method.parameters) { result in
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    public func write(method: Contract.MethodType) -> AnyPublisher<Any, Error> {
        return Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    return
                }
                
                self.write(method: method.name, parameters: method.parameters) { result in
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension ContractInteractor {
    func write(method: String, parameters: [AnyObject], completion: @escaping (Result<Any, Error>) -> Void) {
        // Make sure to call web3 methods from a non-GUI thread because it runs requests asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            do {
                let contract = try self.makeContract()
                let transaction = try self.makeTransaction(from: contract, method: method, parameters: parameters, type: .write)
                self.call(transaction: transaction, completion: completion)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func read(method: String, parameters: [AnyObject], completion: @escaping (Result<Any, Error>) -> Void) {
        // Make sure to call web3 methods from a non-GUI thread because it runs requests asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            do {
                let contract = try self.makeContract()
                let transaction = try self.makeTransaction(from: contract, method: method, parameters: parameters, type: .read)
                self.call(transaction: transaction, completion: completion)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func makeContract() throws -> web3.web3contract {
        let web3 = try Web3.new(contract.rpcURL)
        
        guard let address = EthereumAddress(contract.address) else {
            throw ContractInteractorError.failedToParseAddress
        }
        
        guard let contract = web3.contract(contract.abi, at: address, abiVersion: 2) else {
            throw ContractInteractorError.failedToCreateContract
        }
        
        return contract
    }
    
    func makeTransaction(from contract: web3.web3contract,
                         method: String,
                         parameters: [AnyObject],
                         type: TransactionType) throws  -> ReadTransaction {
        guard let transaction = type.isRead ? contract.read(method, parameters: parameters) :
                contract.write(method, parameters: parameters) else {
            throw ContractInteractorError.failedToCreateTx
        }
        
        return transaction
    }
    
    func call(transaction: ReadTransaction, completion: @escaping (Result<Any, Error>) -> Void) {
        let transactionOptions = defaultOptions
        
        do {
            let result = try transaction.call(transactionOptions: transactionOptions)
            
            guard let resultValue = result["0"] else {
                throw ContractInteractorError.failedToGetResult
            }
            
            completion(.success(resultValue))
        } catch {
            completion(.failure(error))
        }
    }
}

extension ContractInteractor {
    enum TransactionType {
        case read
        case write
        
        var isRead: Bool {
            switch self {
            case .read:
                return true
            case .write:
                return false
            }
        }
    }
}

public enum ContractInteractorError: String, Error, LocalizedError {
    case failedToParseAddress
    case failedToCreateContract
    case failedToCreateTx
    case failedToGetResult
    
    public var errorDescription: String? {
        self.rawValue
    }
}
