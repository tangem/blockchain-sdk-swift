//
//  EthereumUtils.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum EthereumUtils {
    public static func parseEthereumDecimal(_ string: String, decimalsCount: Int) -> Decimal? {
        guard let data = asciiHexToData(string.removeHexPrefix()) else {
            return nil
        }
        
        // Some contracts (namely vBUSD) send 32 bytes of balance plus 64 bytes of zeroes
        let standardBalancePayloadLength = 32
        
        let balanceData: Data
        if data.count > standardBalancePayloadLength,
           data.suffix(from: standardBalancePayloadLength).allSatisfy({ $0 == 0 }) {
            balanceData = data.prefix(standardBalancePayloadLength)
        } else {
            balanceData = data
        }
        
        let decimals = Int16(decimalsCount)
        let handler = makeHandler(with: decimals)
        let balanceWei = dataToDecimal(balanceData, withBehavior: handler)
        if balanceWei.decimalValue.isNaN {
            return nil
        }
        
        let balanceEth = balanceWei.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: decimals), withBehavior: handler)
        if balanceEth.decimalValue.isNaN {
            return nil
        }
        
        return balanceEth as Decimal
    }
    
    private static func dataToDecimal(_ data: Data, withBehavior handler: NSDecimalNumberHandler) -> NSDecimalNumber {
        let reversed = data.reversed()
        var number = NSDecimalNumber(value: 0)
        
        reversed.enumerated().forEach { (arg) in
            let (offset, value) = arg
            let decimalValue = NSDecimalNumber(value: value)
            let multiplier = NSDecimalNumber(value: 256).raising(toPower: offset, withBehavior: handler)
            let addendum = decimalValue.multiplying(by: multiplier, withBehavior: handler)
            number = number.adding(addendum, withBehavior: handler)
        }
        
        return number
    }
    
    private static func asciiHexToData(_ hexString: String) -> Data? {
        var trimmedString = hexString.trimmingCharacters(in: NSCharacterSet(charactersIn: "<> ") as CharacterSet).replacingOccurrences(of: " ", with: "")
        if trimmedString.count % 2 != 0 {
            trimmedString = "0" + trimmedString
        }
        
        guard isValidHex(trimmedString) else {
            return nil
        }
        
        var data = [UInt8]()
        var fromIndex = trimmedString.startIndex
        while let toIndex = trimmedString.index(fromIndex, offsetBy: 2, limitedBy: trimmedString.endIndex) {
            
            let byteString = String(trimmedString[fromIndex..<toIndex])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append(num)
            
            fromIndex = toIndex
        }
        
        return Data(data)
    }
    
    private static func isValidHex(_ asciiHex: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        
        let found = regex.firstMatch(in: asciiHex, options: [], range: NSRange(location: 0, length: asciiHex.count))
        
        if found == nil || found?.range.location == NSNotFound || asciiHex.count % 2 != 0 {
            return false
        }
        
        return true
    }
    
    private static func makeHandler(with decimals: Int16) -> NSDecimalNumberHandler {
        NSDecimalNumberHandler(roundingMode: .plain, scale: decimals,
                               raiseOnExactness: false,  raiseOnOverflow: false,
                               raiseOnUnderflow: false, raiseOnDivideByZero: false)
    }
}
