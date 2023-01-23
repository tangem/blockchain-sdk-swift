//
//  TONBoc.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONCellBocHeader {
    let has_idx: UInt8
    let hash_crc32: UInt8
    let has_cache_bits: UInt8
    let flags: UInt8
    let size_bytes: Int
    let off_bytes: Int
    let cells_num: Int
    let roots_num: Int
    let absent_num: Int
    let tot_cells_size: Int
    let root_list: [Int]
    let index: Bool
    let cells_data: [UInt8]
}
