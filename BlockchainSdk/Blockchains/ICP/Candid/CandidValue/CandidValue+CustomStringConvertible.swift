//
//  CandidValue+CustomStringConvertible.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 16.05.23.
//

import Foundation

extension CandidValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "null"
        case .bool(let bool): return "bool(\(bool))"
        case .natural(let bigUInt): return "natural(\(bigUInt))"
        case .integer(let bigInt): return "integer(\(bigInt))"
        case .natural8(let uInt8): return "natural8(\(uInt8))"
        case .natural16(let uInt16): return "natural16(\(uInt16))"
        case .natural32(let uInt32): return "natural32(\(uInt32))"
        case .natural64(let uInt64): return "natural64(\(uInt64))"
        case .integer8(let int8): return "integer8(\(int8))"
        case .integer16(let int16): return "integer16(\(int16))"
        case .integer32(let int32): return "integer32(\(int32))"
        case .integer64(let int64): return "integer64(\(int64))"
        case .float32(let float): return "float32(\(float))"
        case .float64(let double): return "float64(\(double))"
        case .text(let string): return "text(\(string))"
        case .reserved: return "reserved"
        case .empty: return "empty"
        case .option(let option): return "option(\(option))"
        case .vector(let vector): return "vector(\(vector))"
        case .blob(let data): return "blob(\(data.hexString)"
        case .record(let dictionary): return "record(\(dictionary))"
        case .variant(let variant): return "variant(\(variant))"
        case .function(let function): return "function(\(function))"
        //case .service: return "service()"
        }
    }
}

extension CandidOption: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none(let type): return "none(\(type))"
        case .some(let value): return "\(value)"
        }
    }
}

extension CandidVector: CustomStringConvertible {
    public var description: String {
        let itemsString = values.map { "\($0)" }.joined(separator: ", ")
        return "[\(itemsString)]"
    }
}

extension CandidDictionary: CustomStringConvertible {
    public var description: String {
        let itemsString = candidSortedItems.map { "\($0.hashedKey): \($0.value)" }.joined(separator: ",\n\t")
        return "[\n\t\(itemsString)]"
    }
}

extension CandidDictionaryItemType: CustomStringConvertible {
    public var description: String {
        return "\(hashedKey): \(type)"
    }
}

extension CandidVariant: CustomStringConvertible {
    public var description: String {
        let typesString = candidTypes.map { "\($0.hashedKey)" }.joined(separator: ", ")
        return "[\(typesString)],\nvalue: (\(valueIndex)) \(value)"
    }
}

extension CandidFunction: CustomStringConvertible {
    public var description: String {
        let inputs = signature.inputs.map { "\($0)" }.joined(separator: ", ")
        let outputs = signature.outputs.map { "\($0)" }.joined(separator: ", ")
        let annotations = [
            signature.isQuery ? "Q" : "",
            signature.isOneWay ? "OW" : "",
        ].joined(separator: "|")
        let methodString: String
        if let method = method {
            methodString = "\(method.principalId.hexString).\(method.name)"
        } else {
            methodString = "none"
        }
        return "\(annotations) (\(inputs)) -> (\(outputs)) method: \(methodString)"
    }
}

extension CandidType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .primitive(let primitive): return "\(primitive)"
        case .container(let containerType, let containedType): return "\(containerType)(\(containedType))"
        case .keyedContainer(let containerType, let types):
            let typesString = types.map { "\($0)" }.joined(separator: ", ")
            return "\(containerType)(\(typesString))"
        case .function(let signature):
            let inputs = signature.inputs.map { "\($0)" }.joined(separator: ", ")
            let outputs = signature.outputs.map { "\($0)" }.joined(separator: ", ")
            let annotations = [
                signature.isQuery ? "Q" : "",
                signature.isOneWay ? "OW" : "",
            ].joined(separator: "|")
            return "function( \(annotations) (\(inputs)) -> (\(outputs)))"
//        case .service(let methods):
//            let methodsString = methods.map { "\($0.name): \($0.functionSignature)" }.joined(separator: ",\n")
//            return "service(methods: [\(methodsString)])"
        }
    }
}

extension CandidPrimitiveType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "null"
        case .bool: return "bool"
        case .natural: return "natural"
        case .integer: return "integer"
        case .natural8: return "natural8"
        case .natural16: return "natural16"
        case .natural32: return "natural32"
        case .natural64: return "natural64"
        case .integer8: return "integer8"
        case .integer16: return "integer16"
        case .integer32: return "integer32"
        case .integer64: return "integer64"
        case .float32: return "float32"
        case .float64: return "float64"
        case .text: return "text"
        case .reserved: return "reserved"
        case .empty: return "empty"
        case .option: return "option"
        case .vector: return "vector"
        case .record: return "record"
        case .variant: return "variant"
        case .function: return "function"
        //case .service: return "service"
        }
    }
}
