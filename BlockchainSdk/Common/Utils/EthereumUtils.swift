//
//  EthereumUtils.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum EthereumUtils {
    public static func parseEthereumValue(_ string: String) throws -> Decimal {
        let quantity = try prepareHexString(string)
        guard let balanceData = asciiHexToData(quantity),
              let balanceWei = dataToDecimal(balanceData) else {
                throw ETHError.failedToParseBalance
        }
        
        let balanceEth = balanceWei / Blockchain.ethereum(testnet: false).decimalValue
        return balanceEth
    }
    
    public static func parseEthereumDecimalToken(_ string: String, tokenDecimals: Int) throws -> Decimal {
        let value = try prepareHexString(string)
        guard let balanceData = asciiHexToData(value),
              let balanceWei = dataToDecimalToken(balanceData) else {
            throw ETHError.failedToParseTokenBalance
        }
        
        let balanceEth = balanceWei.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(tokenDecimals)))
        return balanceEth as Decimal
    }
    
    private static func prepareHexString(_ string: String) throws -> String {
        var value = string
        guard value.starts(with: "0x") else {
            throw ETHError.notValidEthereumValue
        }
        
        value.removeFirst(2)
        return value
    }
    
    private static func dataToDecimal(_ data: Data) -> Decimal? {
        if data.count > 8 {
            return nil
        }
        let temp = NSData(bytes: data.reversed(), length: data.count)
        
        let rawPointer = UnsafeRawPointer(temp.bytes)
        let pointer = rawPointer.assumingMemoryBound(to: UInt64.self)
        let value = pointer.pointee
        return NSDecimalNumber(value: value) as Decimal
    }
    
    private static func dataToDecimalToken(_ data: Data) -> NSDecimalNumber? {
        let reversed = data.reversed()
        var number = NSDecimalNumber(value: 0)
        
        reversed.enumerated().forEach { (arg) in
            let (offset, value) = arg
            number = number.adding(NSDecimalNumber(value: value).multiplying(by: NSDecimalNumber(value: 256).raising(toPower: offset)))
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
}
