//
//  APIModels.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.

import Foundation

public typealias APIOrder = [String: [APIInfo]]

public struct APIInfo: Decodable {
    let type: APIType
    let provider: String?
    let url: String?

    var api: PrivateAPI? {
        PrivateAPI(rawValue: provider ?? "")
    }

    public init(type: APIInfo.APIType, provider: String? = nil, url: String? = nil) {
        self.type = type
        self.provider = provider
        self.url = url
    }
}

public extension APIInfo {
    enum APIType: String, Decodable {
        case `public` = "public"
        case `private` = "private"
    }
}

public enum PrivateAPI: String {
    case nownodes
    case quicknode
    case getblock
    case blockchair
    case blockcypher
    case ton
    case tron
    case hedera
    case infura
    case adalite
    case tangemRosetta
    case fireAcademy
    case tangemChia
}

struct NodeInfo: HostProvider {
    let url: URL
    let keyInfo: APIKeyInfo?
    var link: String {
        url.absoluteString
    }

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
