//
//  PolkadotNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ScaleCodec
import Sodium

class PolkadotNetworkService {
    private let rpcProvider: PolkadotJsonRpcProvider
    private let codec = SCALE.default
    
    init(rpcProvider: PolkadotJsonRpcProvider) {
        self.rpcProvider = rpcProvider
    }
    
    func getInfo(for address: String) -> AnyPublisher<BigUInt, Error> {
        Just(())
            .tryMap { _ in
                try storageKey(forAddress: address)
            }
            .flatMap { key in
                self.rpcProvider.storage(key: "0x" + key.hexString)
            }
            .tryMap {
                try self.codec.decode(PolkadotAccountInfo.self, from: Data(hexString: $0))
            }
            .map(\.data.free)
            .eraseToAnyPublisher()
    }
    
    func blockchainMeta(for address: String) -> AnyPublisher<PolkadotBlockchainMeta, Error> {
        let latestBlockPublisher: AnyPublisher<(String, UInt64), Error> = rpcProvider.blockhash(.latest)
            .flatMap { latestBlockHash -> AnyPublisher<(String, UInt64), Error> in
                let latestBlockHashPublisher = Just(latestBlockHash).setFailureType(to: Error.self)
                let latestBlockNumberPublisher = self.rpcProvider
                    .header(latestBlockHash)
                    .map(\.number)
                    .tryMap { encodedBlockNumber in
                        try Self.decodeBigEndian(data: Data(hexString: encodedBlockNumber))
                    }
                
                return Publishers.Zip(latestBlockHashPublisher, latestBlockNumberPublisher).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        
        return Publishers.Zip4(
            rpcProvider.blockhash(.genesis), latestBlockPublisher,
            rpcProvider.accountNextIndex(address),
            rpcProvider.runtimeVersion()
        ).map { genesisHash, latestBlockInfo, nextIndex, runtimeVersion in
            PolkadotBlockchainMeta(
                specVersion: runtimeVersion.specVersion,
                transactionVersion: runtimeVersion.transactionVersion,
                genesisHash: genesisHash,
                blockHash: latestBlockInfo.0,
                nonce: nextIndex,
                era: .init(blockNumber: latestBlockInfo.1, period: 64)
            )
        }
        .eraseToAnyPublisher()
    }
    
    func fee(for extrinsic: Data) -> AnyPublisher<UInt64, Error> {
        rpcProvider.queryInfo("0x" + extrinsic.hexString)
            .tryMap {
                guard let fee = UInt64($0.partialFee) else {
                    throw WalletError.failedToGetFee
                }
                return fee
            }
            .eraseToAnyPublisher()
    }
    
    func submitExtrinsic(data: Data) -> AnyPublisher<String, Error> {
        rpcProvider.submitExtrinsic("0x" + data.hexString)
    }
    
    #warning("TODO: better way?")
    static private func decodeBigEndian(data: Data) throws -> UInt64{
        let codec = SCALE.default
        
        let extraBytes: [UInt8] = Array(repeating: 0, count: max(0, 8 - data.count))
        let reversed = Data(data.reversed() + extraBytes)
        
        return try codec.decode(from: reversed)
    }
    
    private func storageKey(forAddress address: String) throws -> Data {
        guard let addressBytes = PolkadotAddress(string: address)?.bytes(addNullPrefix: false) else {
            throw WalletError.empty
        }
        
        guard let addressBlake = Sodium().genericHash.hash(message: addressBytes.bytes, outputLength: 16) else {
            throw WalletError.empty
        }
        
        // XXHash of "System" module and "Account" storage item.
        let moduleNameHash = Data(hexString: "26aa394eea5630e07c48ae0c9558cef7")
        let storageNameKeyHash = Data(hexString: "b99d880ec681799c0cf30e8886371da9")
        
        let key = moduleNameHash + storageNameKeyHash + addressBlake + addressBytes
        return key
    }
}
