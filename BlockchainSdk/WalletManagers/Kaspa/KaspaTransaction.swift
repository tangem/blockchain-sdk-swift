//
//  KaspaTransaction.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

struct KaspaTransaction {
    let inputs: [BitcoinUnspentOutput]
    let outputs: [KaspaOutput]
    
    func hashForSignatureWitness(inputIndex: Int, connectedScript: Data, prevValue: UInt64)  -> Data {
        

        // MARK: -
        
        var bosHashPrevouts = Data()
        for input in inputs {
            bosHashPrevouts.append(Data(hexString: input.transactionHash))
            bosHashPrevouts.append(UInt32(input.outputIndex).data)
        }
        let hashPrevouts = blake2bDigest(for: bosHashPrevouts)
        
        
        // MARK: -
        
        var bosSequence = Data()
        for _ in inputs {
            bosSequence.append(UInt64(0).data)
        }
        
        let hashSequence = blake2bDigest(for: bosSequence)
        
        // MARK: -
        
        var bosSigOpCounts = Data()
        for _ in inputs {
            bosSigOpCounts.append(UInt8(1).data)
        }

        let hashSigOpCounts = blake2bDigest(for: bosSigOpCounts)
        print(hashSigOpCounts.hex)

        // MARK: -
        
        var bosHashOutputs = Data()
        for output in outputs {
            bosHashOutputs.append(output.amount.data)
            bosHashOutputs.append(UInt16(output.scriptPublicKey.version).data)
            
            let scriptPublicKeyBytes = Data(hexString: output.scriptPublicKey.scriptPublicKey)
            bosHashOutputs.append(UInt64(scriptPublicKeyBytes.count).data)
            bosHashOutputs.append(scriptPublicKeyBytes)
        }
        
        let hashOutputs = blake2bDigest(for: bosHashOutputs)
        
        var data = Data()
        data.append(version().data)
        data.append(hashPrevouts)
        data.append(hashSequence)
        data.append(hashSigOpCounts)
        data.append(Data(hexString: inputs[inputIndex].transactionHash))
        data.append(UInt32(inputs[inputIndex].outputIndex).data)
        data.append(UInt16(0).data)
        data.append(UInt64(connectedScript.count).data)
        data.append(connectedScript)
        data.append(prevValue.data)
        
            
//        uint64ToByteStreamLE(BigInteger.valueOf(inputs.get(inputIndex).getSequenceNumber()), bos);
        data.append(UInt64(inputs[inputIndex].outputIndex).data)
        
//        bos.write(1); // sig op count
        data.append(UInt8(1).data)
        
        
//        bos.write(hashOutputs);
        data.append(hashOutputs)
        
        
//        uint64ToByteStreamLE(BigInteger.valueOf(getLockTime()), bos);
        data.append(UInt64(0).data)
        
        
//        bos.write(new byte[20]); // subnetwork id
        data.append(Data(repeating: 0, count: 20))
        
        
//        uint64ToByteStreamLE(BigInteger.valueOf(0), bos); // gas
        data.append(UInt64(0).data)
        
        
//        bos.write(new byte[32]); // payload hash
        data.append(Data(repeating: 0, count: 32))
        
//        bos.write(sigHashType); // sig op count
        data.append(UInt8(1).data)
        

        
        
        
        print("data:")
        print(data.hex)
        
        
        var finalData = Data()
        let TRANSACTION_SIGNING_ECDSA_DOMAIN_HASH = "TransactionSigningHashECDSA".data(using: .utf8)!.sha256()
        finalData.append(TRANSACTION_SIGNING_ECDSA_DOMAIN_HASH)
        finalData.append(blake2bDigest(for: data))
        
        print("final data:")
        print(finalData.hex)
        
        return finalData.sha256()
    }
    
    func version() -> UInt16 {
        return 0
    }
    
    func blake2bDigest(for data: Data) -> Data {
        let key = "TransactionSigningHash".data(using: .utf8)?.bytes ?? []
        let length = 32
        return Data(Sodium().genericHash.hash(message: data.bytes, key: key, outputLength: length) ?? [])
    }
}


