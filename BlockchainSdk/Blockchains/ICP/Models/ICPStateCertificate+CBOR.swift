//
//  ICPStateCertificate.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 02.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import PotentCBOR

// MARK: CBOR Parsing
enum ICPStateCertificateError: Error {
    case invalidCertificateStructure
    case invalidSignature
}

extension ICPStateCertificate {
    static func parse(_ cbor: CBOR) throws -> ICPStateCertificate {
        guard let map = cbor.mapValue,
              let signature = map["signature"]?.bytesStringValue,
              let root = cbor["tree"]
        else {
            throw ICPStateCertificateError.invalidCertificateStructure
        }
        // TODO: parse delegation https://internetcomputer.org/docs/current/references/ic-interface-spec/#certification-delegation
        //let delegation = map["delegation"]?.mapValue
        //let delegationSubnetId = delegation?["subnet_id"]?.bytesStringValue // Principal
        //let delegationCertificateBlob = delegation?["certificate"]?.bytesStringValue // Certificate
        //let delegationCertificate = ICPCertificate.parse(delegationCertificateBlob)
        return ICPStateCertificate(
            tree: try .buildTree(from: root),
            signature: signature
        )
    }
}

extension ICPStateCertificate.HashTreeNode {
    static func buildTree(from cbor: CBOR) throws -> ICPStateCertificate.HashTreeNode {
        guard let array = cbor.arrayValue,
              let hashTreeType: Int = array.first?.integerValue(),
              let nodeType = HashTreeNodeType(rawValue: hashTreeType)
        else {
            throw ICPStateCertificateError.invalidCertificateStructure
        }
        switch nodeType {
        case .empty:
            return .empty
        case .fork:
            guard array.count == 3 else {
                throw ICPStateCertificateError.invalidCertificateStructure
            }
            return .fork(
                left: try buildTree(from: array[1]),
                right: try buildTree(from: array[2])
            )
        case .labeled:
            guard array.count == 3,
                  let labelData = array[1].bytesStringValue else {
                throw ICPStateCertificateError.invalidCertificateStructure
            }
            return .labeled(labelData, try buildTree(from: array[2]))
        case .leaf:
            guard array.count == 2,
                  let stateData = array[1].bytesStringValue else {
                throw ICPStateCertificateError.invalidCertificateStructure
            }
            return .leaf(stateData)
        case .pruned:
            guard array.count == 2,
                  let hash = array[1].bytesStringValue else {
                throw ICPStateCertificateError.invalidCertificateStructure
            }
            return .pruned(hash)
        }
    }
    
    private enum HashTreeNodeType: Int {
        case empty      = 0
        case fork       = 1
        case labeled    = 2
        case leaf       = 3
        case pruned     = 4
    }
}
