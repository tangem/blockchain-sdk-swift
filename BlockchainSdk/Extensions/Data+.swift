//
//  Data+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//
//extension Data {
//    func sha3(_ variant: SHA3.Variant) -> Data {
//        return Data(Digest.sha3(bytes, variant: variant))
//    }
//}

import Foundation

extension Data {
	var doubleSha256: Data {
		sha256().sha256()
	}
	
	var ripemd160: Data {
		RIPEMD160.hash(message: self)
	}
	
	var sha256Ripemd160: Data {
		RIPEMD160.hash(message: sha256())
	}
}
