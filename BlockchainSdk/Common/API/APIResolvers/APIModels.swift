//
//  APIModels.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.

import Foundation

public typealias APIOrder = [String: [NetworkProviderType]]

public enum NetworkProviderType {
    case `public`(link: String)
    case nownodes
    case quicknode
    case getblock
    case blockchair
    case blockcypher
    case ton
    case tron
    case arkhiaHedera
    case infura
    case adalite
    case tangemRosetta
    case fireAcademy
    case tangemChia
    case solana
    case kaspa
}

struct NodeInfo: HostProvider {
    let url: URL
    let keyInfo: APIKeyInfo?

    var link: String { url.absoluteString }

    var host: String { link }

    init(url: URL, keyInfo: APIKeyInfo? = nil) {
        self.url = url
        self.keyInfo = keyInfo
    }
}

struct APIKeyInfo {
    let headerName: String
    let headerValue: String
}
