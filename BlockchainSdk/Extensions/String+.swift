//
//  String+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

fileprivate var hexPrefix = "0x"

extension String {
    func contains(_ string: String, ignoreCase: Bool = true) -> Bool {
        return self.range(of: string, options: ignoreCase ? .caseInsensitive : []) != nil
    }

    public func hasHexPrefix() -> Bool {
        return self.lowercased().hasPrefix(hexPrefix)
    }

    public func removeHexPrefix() -> String {
        if hasHexPrefix() {
            return String(dropFirst(2))
        }
        
        return self
    }

    public func addHexPrefix() -> String {
        if lowercased().hasPrefix(hexPrefix) {
            return self
        }

        return hexPrefix.appending(self)
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

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }

    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
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

    func localized(_ argument: CVarArg) -> String {
        return String(format: localized, argument)
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(self.startIndex, offsetBy: bounds.lowerBound)
        let end = index(self.startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
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
