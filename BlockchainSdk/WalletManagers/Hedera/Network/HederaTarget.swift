//
//  HederaTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

// TODO: Andrey Fedorov - Add actual implementation (IOS-4556)
struct HederaTarget {
    let baseURL: URL
    let target: Target
}

// MARK: - Auxiliary types

extension HederaTarget {
    enum Target {}
}

// MARK: - TargetType protocol conformance

extension HederaTarget: TargetType {
    var path: String {
        return ""
    }

    var method: Moya.Method {
        return .get
    }

    var task: Moya.Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return nil
    }
}
