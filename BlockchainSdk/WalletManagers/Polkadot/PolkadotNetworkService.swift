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

class PolkadotNetworkService {
    private let rpcProvider: PolkadotJsonRpcProvider
    private let codec = SCALE.default
    
    init(rpcProvider: PolkadotJsonRpcProvider) {
        self.rpcProvider = rpcProvider
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
    
    func submitExtrinsic(data: Data) -> AnyPublisher<Void, Error> {
        rpcProvider.submitExtrinsic("0x" + data.hexString)
            .map { _ in
                ()
            }
            .eraseToAnyPublisher()
    }
    
    static private func decodeBigEndian(data: Data) throws -> UInt64{
        let codec = SCALE.default
        
        let extraBytes: [UInt8] = Array(repeating: 0, count: max(0, 8 - data.count))
        let reversed = Data(data.reversed() + extraBytes)
        
        return try codec.decode(from: reversed)
    }
}
