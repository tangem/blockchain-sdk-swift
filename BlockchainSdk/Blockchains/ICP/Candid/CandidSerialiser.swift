//
//  CandidSerialiser.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 27.04.23.
//

import Foundation
import BigInt
//import OrderedCollections

/// see section Serialisation at the bottom of
/// https://github.com/dfinity/candid/blob/master/spec/Candid.md
class CandidSerialiser {
    static let magicBytes = Data("DIDL".utf8)  //0x4449444C
    
    /// Serialises a single candid value. The given CandidValue instance is wrapped in a single element list before being serialised.
    /// - Parameter value: An optional CandidValue, if none provided this will serialise an empty list.
    /// - Returns: the Candid serialisation of the given CandidValue
    func encode(_ value: CandidValue?) -> Data {
        guard let value = value else {
            return encode([])
        }
        return encode([value])
    }
    
    /// Serialises a list of Candid Values
    /// - Parameter values: The Candid Values to be serialised
    /// - Returns: The serialisation of the given Candid Values
    func encode(_ values: [CandidValue]) -> Data {
        let typeTable = CandidTypeTable()
        let encodableValues = values.map { Self.buildTree($0, typeTable) }
        return Self.magicBytes +
                typeTable.encode() +
                ICPCryptography.Leb128.encodeUnsigned(UInt(encodableValues.count)) +
                encodableValues.map { $0.encodeType() }.joinedData() +
                encodableValues.map { $0.encodeValue() }.joinedData()
    }
}

private extension CandidSerialiser {
    static func buildTree(_ value: CandidValue, _ typeTable: CandidTypeTable) -> CandidEncodableValue {
        switch value {
        case .null: return .null
        case .bool(let bool): return .bool(bool)
        case .natural(let bigUInt): return .natural(bigUInt)
        case .integer(let bigInt): return .integer(bigInt)
        case .natural8(let uInt8): return .natural8(uInt8)
        case .natural16(let uInt16): return .natural16(uInt16)
        case .natural32(let uInt32): return .natural32(uInt32)
        case .natural64(let uInt64): return .natural64(uInt64)
        case .integer8(let int8): return .integer8(int8)
        case .integer16(let int16): return .integer16(int16)
        case .integer32(let int32): return .integer32(int32)
        case .integer64(let int64): return .integer64(int64)
        case .float32(let float): return .float32(float)
        case .float64(let double): return .float64(double)
        case .text(let string): return .text(string)
        case .reserved: return .reserved
        case .empty: return .empty
            
        case .option(let option):
            let typeReference = typeTable.getReference(for: value.candidType)
            switch option {
            case .none:
                return .option(typeRef: typeReference, nil)
            case .some(let value):
                return .option(typeRef: typeReference, buildTree(value, typeTable))
            }
            
        case .vector(let vector):
            let typeReference = typeTable.getReference(for: value.candidType)
            return .vector(
                typeRef: typeReference,
                vector.values.map { buildTree($0, typeTable) }
            )
            
        case .blob(let data):
            let typeReference = typeTable.getReference(for: value.candidType)
            return .blob(typeRef: typeReference, data)
            
        case .record(let dictionary):
            let typeReference = typeTable.getReference(for: value.candidType)
            return .record(
                typeRef: typeReference,
                dictionary.candidSortedItems.map { .init(
                    hashedKey: $0.hashedKey,
                    value: buildTree($0.value, typeTable)
                )}
            )
            
        case .variant(let variant):
            let typeReference = typeTable.getReference(for: value.candidType)
            return .variant(
                typeRef: typeReference,
                .init(
                    valueIndex: variant.valueIndex,
                    value: buildTree(variant.value, typeTable)
                )
            )
            
        case .function(let function):
            let typeReference = typeTable.getReference(for: value.candidType)
            guard let method = function.method else {
                return .function(typeRef: typeReference, nil)
            }
            return .function(typeRef: typeReference, method)
            
//        case .service(let service):
//            let typeReference = typeTable.getReference(for: value.candidType)
//            return .service(typeRef: typeReference, service.principalId)
        }
    }
}

private extension Array where Element == Data {
    func joinedData() -> Data { reduce(Data(), +) }
}

private struct CandidTypeData: Equatable {
    enum EncodableType: Equatable {
        case signed(Int)
        case unsigned(UInt)
        case data(Data)
        
        func encode() -> Data {
            switch self {
            case .signed(let int): return ICPCryptography.Leb128.encodeSigned(int)
            case .unsigned(let uInt): return ICPCryptography.Leb128.encodeUnsigned(uInt)
            case .data(let data): return data
            }
        }
    }
    let types: [EncodableType]
    func encode() -> Data {
        types.map { $0.encode() }.joinedData()
    }
}

private class CandidTypeTable {
    private var customTypes: [CandidTypeData] = []
    
    func getReference(for type: CandidType) -> Int {
        switch type {
        case .primitive(let type):
            return type.rawValue
            
        case .container(let containerType, let valueType):
            let typeData = CandidTypeData(types: [
                .signed(containerType.rawValue),
                .signed(getReference(for: valueType))
            ])
            return addOrFind(typeData)
            
        case .keyedContainer(let containerType, let types):
            let typeData = CandidTypeData(
                types:
                    [
                        .signed(containerType.rawValue),
                        .unsigned(UInt(types.count))
                    ]
                    + types.flatMap {
                        [
                            .unsigned(UInt($0.hashedKey)),
                            .signed(getReference(for: $0.type))
                        ]
                    }
            )
            return addOrFind(typeData)
            
        case .function(let functionSignature):
            var typeData: [CandidTypeData.EncodableType] = []
            typeData.append(.signed(CandidPrimitiveType.function.rawValue))
            typeData.append(.unsigned(UInt(functionSignature.inputs.count)))
            typeData.append(contentsOf: functionSignature.inputs.map { .signed(getReference(for: $0)) })
            typeData.append(.unsigned(UInt(functionSignature.outputs.count)))
            typeData.append(contentsOf: functionSignature.outputs.map { .signed(getReference(for: $0)) })
            var annotations: [CandidTypeData.EncodableType] = []
            if functionSignature.isQuery { annotations.append(.unsigned(0x01)) }
            if functionSignature.isOneWay { annotations.append(.unsigned(0x02)) }
            typeData.append(.unsigned(UInt(annotations.count)))
            typeData.append(contentsOf: annotations)
            return addOrFind(CandidTypeData(types: typeData))
            
//        case .service(let methods):
//            let typeData = CandidTypeData(
//                types:
//                    [
//                        .signed(CandidPrimitiveType.service.rawValue),
//                        .unsigned(UInt(methods.count))
//                    ]
//                + methods.flatMap {
//                    [
//                        .unsigned(UInt($0.name.count)),
//                        .data(Data($0.name.utf8)),
//                        .signed(getReference(for: .function($0.functionSignature)))
//                    ]
//                }
//            )
//            return addOrFind(typeData)
        }
    }
    
    func encode() -> Data {
        ICPCryptography.Leb128.encodeUnsigned(UInt(customTypes.count)) +
        customTypes.map { $0.encode() }.joinedData()
    }
    
    private func addOrFind(_ typeData: CandidTypeData) -> Int {
        guard let index = customTypes.firstIndex(of: typeData) else {
            customTypes.append(typeData)
            return customTypes.count - 1
        }
        return index
    }
}

private indirect enum CandidEncodableValue {
    struct DictionaryEncodableItem {
        let hashedKey: Int
        let value: CandidEncodableValue
    }
    struct VariantEncodableItem {
        let valueIndex: UInt
        let value: CandidEncodableValue
    }
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
    case reserved
    case empty
    case text(String)
    case option(typeRef: Int, CandidEncodableValue?)
    case vector(typeRef: Int, [CandidEncodableValue])
    case blob(typeRef: Int, Data)
    case record(typeRef: Int, [DictionaryEncodableItem])
    case variant(typeRef: Int, VariantEncodableItem)
    case function(typeRef: Int, CandidFunction.ServiceMethod?)
    case service(typeRef: Int, Data?)
    
    func encodeType() -> Data {
        let encodeSigned: (Int) -> Data = ICPCryptography.Leb128.encodeSigned
        switch self {
        case .null: return encodeSigned(CandidPrimitiveType.null.rawValue)
        case .bool: return encodeSigned(CandidPrimitiveType.bool.rawValue)
        case .natural: return encodeSigned(CandidPrimitiveType.natural.rawValue)
        case .integer: return encodeSigned(CandidPrimitiveType.integer.rawValue)
        case .natural8: return encodeSigned(CandidPrimitiveType.natural8.rawValue)
        case .natural16: return encodeSigned(CandidPrimitiveType.natural16.rawValue)
        case .natural32: return encodeSigned(CandidPrimitiveType.natural32.rawValue)
        case .natural64: return encodeSigned(CandidPrimitiveType.natural64.rawValue)
        case .integer8: return encodeSigned(CandidPrimitiveType.integer8.rawValue)
        case .integer16: return encodeSigned(CandidPrimitiveType.integer16.rawValue)
        case .integer32: return encodeSigned(CandidPrimitiveType.integer32.rawValue)
        case .integer64: return encodeSigned(CandidPrimitiveType.integer64.rawValue)
        case .float32: return encodeSigned(CandidPrimitiveType.float32.rawValue)
        case .float64: return encodeSigned(CandidPrimitiveType.float64.rawValue)
        case .reserved: return encodeSigned(CandidPrimitiveType.reserved.rawValue)
        case .empty: return encodeSigned(CandidPrimitiveType.empty.rawValue)
        case .text: return encodeSigned(CandidPrimitiveType.text.rawValue)
        case .blob(let typeReference, _),
             .option(let typeReference, _),
             .vector(let typeReference, _),
             .record(let typeReference, _),
             .variant(let typeReference, _),
             .function(let typeReference, _),
             .service(let typeReference, _):
            return encodeSigned(typeReference)
        }
    }
    
    func encodeValue() -> Data {
        let encodeUnsigned: (UInt) -> Data = ICPCryptography.Leb128.encodeUnsigned
        switch self {
        case .null: return Data()
        case .bool(let bool): return Data(from: bool)
        case .natural(let bigUInt): return ICPCryptography.Leb128.encodeUnsigned(bigUInt)
        case .integer(let bigInt): return ICPCryptography.Leb128.encodeSigned(bigInt)
        case .natural8(let uInt8): return uInt8.icpBytes
        case .natural16(let uInt16): return uInt16.icpBytes
        case .natural32(let uInt32): return uInt32.icpBytes
        case .natural64(let uInt64): return uInt64.icpBytes
        case .integer8(let int8): return int8.icpBytes
        case .integer16(let int16): return int16.icpBytes
        case .integer32(let int32): return int32.icpBytes
        case .integer64(let int64): return int64.icpBytes
        case .float32(let float): return float.icpBytes
        case .float64(let double): return double.icpBytes
        case .reserved: return Data()
        case .empty: return Data()
        case .text(let string):
            let utf8 = Data(string.utf8)
            return encodeUnsigned(UInt(utf8.count)) + utf8
            
        case .blob(_, let data): return encodeUnsigned(UInt(data.count)) + data
            
        case .option(_, let optionalValue):
            guard let presentValue = optionalValue else {
                return Data([0x00])
            }
            return Data([0x01]) + presentValue.encodeValue()
            
        case .vector(_, let array):
            return ([encodeUnsigned(UInt(array.count))]
                    + array.map { $0.encodeValue() })
                    .joinedData()
            
        case .record(_, let values):
            return values.map { $0.value.encodeValue() }.joinedData()
            
        case .variant(_, let value):
            return encodeUnsigned(value.valueIndex) + value.value.encodeValue()
            
        case .function(_, let method):
            guard let method = method else {
                return Data([0x00])
            }
            let methodName = Data(method.name.utf8)
            return Data([0x01]) + encodeUnsigned(UInt(method.principalId.count)) + method.principalId
                 + Data([0x01]) + encodeUnsigned(UInt(methodName.count)) + methodName
            
        case .service(_, let principalId):
            guard let principalId = principalId else {
                return Data([0x00])
            }
            return Data([0x01]) + encodeUnsigned(UInt(principalId.count)) + principalId
        }
    }
}
