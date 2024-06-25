//
//  CandidValue+Value.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation
import BigInt

extension CandidValue {
    var boolValue: Bool? {
        guard case .bool(let bool) = self else { return nil }
        return bool
    }
    
    var naturalValue: BigUInt? {
        guard case .natural(let bigUInt) = self else { return nil }
        return bigUInt
    }
    
    var natural8Value: UInt8? {
        guard case .natural8(let uInt8) = self else { return nil }
        return uInt8
    }
    
    var natural16Value: UInt16? {
        guard case .natural16(let uInt16) = self else { return nil }
        return uInt16
    }
    
    var natural32Value: UInt32? {
        guard case .natural32(let uInt32) = self else { return nil }
        return uInt32
    }
    
    var natural64Value: UInt64? {
        guard case .natural64(let uInt64) = self else { return nil }
        return uInt64
    }
    
    var integerValue: BigInt? {
        guard case .integer(let bigInt) = self else { return nil }
        return bigInt
    }
    
    var integer8Value: Int8? {
        guard case .integer8(let int8) = self else { return nil }
        return int8
    }
    
    var integer16Value: Int16? {
        guard case .integer16(let int16) = self else { return nil }
        return int16
    }
    
    var integer32Value: Int32? {
        guard case .integer32(let int32) = self else { return nil }
        return int32
    }
    
    var integer64Value: Int64? {
        guard case .integer64(let int64) = self else { return nil }
        return int64
    }
    
    var float32Value: Float? {
        guard case .float32(let float) = self else { return nil }
        return float
    }
    
    var float64Value: Double? {
        guard case .float64(let double) = self else { return nil }
        return double
    }
    
    var textValue: String? {
        guard case .text(let string) = self else { return nil }
        return string
    }
    
    var blobValue: Data? {
        guard case .blob(let data) = self else { return nil }
        return data
    }
    
    var optionValue: CandidOption? {
        guard case .option(let candidOption) = self else { return nil }
        return candidOption
    }
    
    var vectorValue: CandidVector? {
        guard case .vector(let candidVector) = self else { return nil }
        return candidVector
    }
    
    var recordValue: CandidDictionary? {
        guard case .record(let candidDictionary) = self else { return nil }
        return candidDictionary
    }
    
    var variantValue: CandidVariant? {
        guard case .variant(let candidVariant) = self else { return nil }
        return candidVariant
    }
    
    var functionValue: CandidFunction? {
        guard case .function(let candidFunction) = self else { return nil }
        return candidFunction
    }
    
//    var serviceValue: CandidService? {
//        guard case .service(let candidService) = self else { return nil }
//        return candidService
//    }
}
