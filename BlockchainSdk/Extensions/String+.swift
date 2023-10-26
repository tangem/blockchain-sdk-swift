//
//  String+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    func contains(_ string: String, ignoreCase: Bool = true) -> Bool {
        return self.range(of: string, options: ignoreCase ? .caseInsensitive : []) != nil
    }
    
    func removeHexPrefix() -> String {
        if self.lowercased().starts(with: "0x") {
            return String(self[self.index(self.startIndex, offsetBy: 2)...])
        }
        
        return self
    }
    
    func removeBchPrefix() -> String {
        if let index = self.firstIndex(where: { $0 == ":" }) {
            let startIndex = self.index(index, offsetBy: 1)
            return String(self.suffix(from: startIndex))
        }

        return self
    }
    
    func stripLeadingZeroes() -> String {
        self.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }
    
    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    func serialize() -> String {
        Data(hexString: self).aligned().hexString
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    var localized: String {
        return NSLocalizedString(self, bundle: .blockchainBundle, comment: "")
    }
    
    func localized(_ arguments: [CVarArg]) -> String {
        return String(format: localized, arguments: arguments)
    }

    func localized(_ arguments: CVarArg...) -> String {
        return String(format: localized, arguments)
    }
    
    public static var unknown: String {
        "Unknown"
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
