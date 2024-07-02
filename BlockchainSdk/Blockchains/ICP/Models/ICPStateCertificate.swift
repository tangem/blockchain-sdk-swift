//
//  ICPStateCertificate.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 02.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// see https://internetcomputer.org/docs/current/references/ic-interface-spec/#certification
/// and https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate
struct ICPStateCertificate {
    let tree: HashTreeNode
    let signature: Data
    
    indirect enum HashTreeNode: Equatable {
        case empty
        case fork(left: HashTreeNode, right: HashTreeNode)
        case labeled(Data, HashTreeNode)
        case leaf(Data)
        case pruned(Data)
        
        static func labeled(_ string: String, _ node: HashTreeNode) -> HashTreeNode {
            return .labeled(Data(string.utf8), node)
        }
    }
}

// MARK: Lookup
extension ICPStateCertificate.HashTreeNode {
    func getNode(for path: ICPStateTreePath) -> ICPStateCertificate.HashTreeNode? {
        if path.isEmpty { return self }
        switch self {
        case .fork(let left, let right):
            return left.getNode(for: path) ?? right.getNode(for: path)
            
        case .labeled(let label, let child):
            guard label == path.firstComponent?.encoded() else { return nil }
            return child.getNode(for: path.removingFirstComponent)
            
        case .empty, .leaf, .pruned: return nil
        }
    }
    
    func getValue(for path: ICPStateTreePath) -> Data? {
        guard case .leaf(let data) = getNode(for: path) else {
            return nil
        }
        return data
    }
    // TODO: implement lookup algorithm producing found, absent, unknown
    // https://internetcomputer.org/docs/current/references/ic-interface-spec/#lookup
}
