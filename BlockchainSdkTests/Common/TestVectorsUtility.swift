//
//  TestVectorsUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 24.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class TestVectorsUtility {
    
    func getTestVectors<T: Decodable>(from filename: String) throws -> T? {
        guard let url = Bundle(for: type(of: self)).url(forResource: filename, withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true

        return try decoder.decode(T?.self, from: data)
    }
    
}
