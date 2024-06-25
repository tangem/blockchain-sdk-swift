//
//  CandidSerialiser.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 26.04.23.
//

import Foundation
import BigInt

/// https://github.com/dfinity/candid/blob/master/spec/Candid.md
public indirect enum CandidValue: Equatable {
    case null
    case bool(Bool)
    case natural(BigUInt)
    case integer(BigInt)
    case natural8(UInt8)
    case natural16(UInt16)
    case natural32(UInt32)
    case natural64(UInt64)
    case integer8(Int8)
    case integer16(Int16)
    case integer32(Int32)
    case integer64(Int64)
    case float32(Float)
    case float64(Double)
    case text(String)
    case blob(Data)
    case reserved
    case empty
    case option(CandidOption)
    case vector(CandidVector)
    case record(CandidDictionary)
    case variant(CandidVariant)
    case function(CandidFunction)
    //case service(CandidService)
}

// MARK: CandidType
public extension CandidValue {
    var candidType: CandidType {
        switch self {
        case .null: return .primitive(.null)
        case .bool: return .primitive(.bool)
        case .natural: return .primitive(.natural)
        case .integer: return .primitive(.integer)
        case .natural8: return .primitive(.natural8)
        case .natural16: return .primitive(.natural16)
        case .natural32: return .primitive(.natural32)
        case .natural64: return .primitive(.natural64)
        case .integer8: return .primitive(.integer8)
        case .integer16: return .primitive(.integer16)
        case .integer32: return .primitive(.integer32)
        case .integer64: return .primitive(.integer64)
        case .float32: return .primitive(.float32)
        case .float64: return .primitive(.float64)
        case .text: return .primitive(.text)
        case .reserved: return .primitive(.reserved)
        case .empty: return .primitive(.empty)
        case .blob: return .container(.vector, .primitive(.natural8))
        case .option(let option): return .container(.option, option.containedType)
        case .vector(let vector): return .container(.vector, vector.containedType)
        case .record(let dictionary): return .keyedContainer(.record, dictionary.candidTypes)
        case .variant(let variant): return .keyedContainer(.variant, variant.candidTypes)
        case .function(let function): return .function(function.signature)
        //case .service(let service): return .service(service.methods)
        }
    }
}
