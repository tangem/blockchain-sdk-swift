//
//  CandidDeserialiser.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 01.05.23.
//

import Foundation

/// see section Serialisation at the bottom of
/// https://github.com/dfinity/candid/blob/master/spec/Candid.md
class CandidDeserialiser {
    /// Desrialises the given data into a list of CandidValues or throws a `CandidDeserialisationError`
    /// - Parameter data: Candid serialised Data
    /// - Returns: The list of deserialised Candid Values
    func decode(_ data: Data) throws -> [CandidValue] {
        guard data.prefix(CandidSerialiser.magicBytes.count) == CandidSerialiser.magicBytes else {
            throw CandidDeserialisationError.invalidPrefix
        }
        let unwrappedData = data.suffix(from: CandidSerialiser.magicBytes.count)
        let stream = ByteInputStream(unwrappedData)
        let typeTable = try CandidDecodableTypeTable(stream)
        let nCandidValues: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
        let decodedTypes = try (0..<nCandidValues).map { _ in
            let typeRef: Int = try ICPCryptography.Leb128.decodeSigned(stream)
            let candidType = try typeTable.getTypeForReference(typeRef)
            return candidType
        }
        let decodedValues = try decodedTypes.map { candidType in
            let decodedValue = try CandidValue.decodeValue(candidType, stream)
            return decodedValue
        }
        guard !stream.hasBytesAvailable else {
            throw CandidDeserialisationError.unserialisedBytesLeft
        }
        return decodedValues
    }
}

enum CandidDeserialisationError: Error {
    case invalidPrefix
    case invalidPrimitive
    case invalidTypeReference
    case invalidUtf8String
    case unserialisedBytesLeft
}

private class CandidDecodableTypeTable {
    private let types: [CandidType]
    
    init(_ stream: ByteInputStream) throws {
        let typeCount: UInt = try ICPCryptography.Leb128.decodeUnsigned(stream)
        let typesRawData = try (0..<typeCount).map { _ in
            try CandidTypeTableData.decode(stream)
        }
        types = try typesRawData.map { try Self.buildType($0, from: typesRawData) }
    }
    
    private static func buildType(_ type: CandidTypeTableData, from rawTypeData: [CandidTypeTableData]) throws -> CandidType {
        switch type {
        case .container(let containerType, let containedType):
            let referencedType = try candidType(for: containedType, with: rawTypeData)
            return .container(containerType, referencedType)
            
        case .keyedContainer(let containerType, let rows):
            let rowTypes = try rows.map {
                let rowType = try candidType(for: $0.type, with: rawTypeData)
                return CandidDictionaryItemType(hashedKey: $0.hashedKey, type: rowType)
            }
            return .keyedContainer(containerType, rowTypes)
            
        case .functionSignature(let inputTypes, let outputTypes, let annotations):
            return .function(.init(
                inputs: try inputTypes.map { try candidType(for: $0, with: rawTypeData) },
                outputs: try outputTypes.map { try candidType(for: $0, with: rawTypeData) },
                isQuery: annotations.contains(0x01),
                isOneWay: annotations.contains(0x02)
            ))
            
//        case .service(let methods):
//            return .service(try methods.map {
//                guard let signature = try candidType(for: $0.functionType, with: rawTypeData).functionSignature else {
//                    throw CandidDeserialisationError.invalidTypeReference
//                }
//                return CandidService.Method(
//                    name: $0.name,
//                    functionSignature: signature
//                )
//            })
        }
    }
    
    private static func candidType(for type: Int, with rawTypeData: [CandidTypeTableData]) throws -> CandidType {
        if type >= 0 {
            guard rawTypeData.count > type else {
                throw CandidDeserialisationError.invalidTypeReference
            }
            return try buildType(rawTypeData[type], from: rawTypeData)
            
        } else {
            guard let primitiveContainedType = CandidPrimitiveType(rawValue: type) else {
                throw CandidDeserialisationError.invalidPrimitive
            }
            return .primitive(primitiveContainedType)
        }
    }
    
    func getTypeForReference(_ reference: Int) throws -> CandidType {
        if reference < 0 {
            guard let primitive = CandidPrimitiveType(rawValue: reference) else {
                throw CandidDeserialisationError.invalidPrimitive
            }
            return .primitive(primitive)
        }
        guard types.count > reference else {
            throw CandidDeserialisationError.invalidTypeReference
        }
        return types[reference]
    }
}

private enum CandidTypeTableData {
    typealias KeyedContainerRowData = (hashedKey: Int, type: Int)
    typealias ServiceMethod = (name: String, functionType: Int)
    case container(containerType: CandidPrimitiveType, containedType: Int)
    case keyedContainer(containerType: CandidPrimitiveType, rows: [KeyedContainerRowData])
    case functionSignature(inputTypes: [Int], outputTypes: [Int], annotations: [UInt])
    //case service(methods: [ServiceMethod])
    
    static func decode(_ stream: ByteInputStream) throws -> CandidTypeTableData {
        let candidType: Int = try ICPCryptography.Leb128.decodeSigned(stream)
        guard let primitive = CandidPrimitiveType(rawValue: candidType) else {
            throw CandidDeserialisationError.invalidPrimitive
        }
        switch primitive {
        case .record, .variant:
            let nRows: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let rows: [KeyedContainerRowData] = try (0..<nRows).map { _ in
                (
                    try ICPCryptography.Leb128.decodeUnsigned(stream), // hashed key
                    try ICPCryptography.Leb128.decodeSigned(stream)  // type
                )
            }
            return .keyedContainer(containerType: primitive, rows: rows)
            
        case .function:
            let nInputs: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let inputTypes: [Int] = try (0..<nInputs).map { _ in
                try ICPCryptography.Leb128.decodeSigned(stream)
            }
            let nOutputs: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let outputTypes: [Int] = try (0..<nOutputs).map { _ in
                try ICPCryptography.Leb128.decodeSigned(stream)
            }
            let nAnnotations: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let annotations: [UInt] = try (0..<nAnnotations).map { _ in
                try ICPCryptography.Leb128.decodeUnsigned(stream)
            }
            return .functionSignature(
                inputTypes: inputTypes,
                outputTypes: outputTypes,
                annotations: annotations
            )
            
//        case .service:
//            let nMethods: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
//            let methods: [ServiceMethod] = try (0..<nMethods).map { _ in
//                let nameLength: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
//                let nameData = try stream.readNextBytes(nameLength)
//                guard let name = String(data: nameData, encoding: .utf8) else {
//                    throw CandidDeserialisationError.invalidUtf8String
//                }
//                let functionReference: Int = try ICPCryptography.Leb128.decodeSigned(stream)
//                return ServiceMethod(name: name, functionType: functionReference)
//            }
//            return .service(methods: methods)
            
        default:
            // all other types have a single contained type, either primitive or ref
            let containedType: Int = try ICPCryptography.Leb128.decodeSigned(stream)
            return .container(containerType: primitive, containedType: containedType)
        }
    }
}

private extension CandidValue {
    static func decodeValue(_ type: CandidType, _ stream: ByteInputStream) throws -> CandidValue {
        switch type.primitiveType {
        case .null: return .null
        case .bool: return .bool(try stream.readNextByte() != 0)
        case .natural: return .natural(try ICPCryptography.Leb128.decodeUnsigned(stream))
        case .integer: return .integer(try ICPCryptography.Leb128.decodeSigned(stream))
        case .natural8: return .natural8(try .readFrom(stream))
        case .natural16: return .natural16(try .readFrom(stream))
        case .natural32: return .natural32(try .readFrom(stream))
        case .natural64: return .natural64(try .readFrom(stream))
        case .integer8: return .integer8(try .readFrom(stream))
        case .integer16: return .integer16(try .readFrom(stream))
        case .integer32: return .integer32(try .readFrom(stream))
        case .integer64: return .integer64(try .readFrom(stream))
        case .float32: return .float32(try .readFrom(stream))
        case .float64: return .float64(try .readFrom(stream))
        case .text:
            let count: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let data = try stream.readNextBytes(count)
            guard let string = String(data: data, encoding: .utf8) else {
                throw CandidDeserialisationError.invalidUtf8String
            }
            return .text(string)
        case .reserved: return .reserved
        case .empty: return .empty
        case .option:
            let containedType = type.containedType!
            let isPresent = try stream.readNextByte() == 1
            if isPresent {
                let value = try decodeValue(containedType, stream)
                return .option(value)
            } else {
                return .option(containedType)
            }
            
        case .vector:
            let containedType = type.containedType!
            let nItems: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            let items = try (0..<nItems).map { _ in
                try decodeValue(containedType, stream)
            }
            // special handling of vector(nat8). We convert them to blob(Data)
            if containedType.primitiveType == .natural8 {
                return .blob(Data(items.map { $0.natural8Value! }))
            }
            return .vector(try CandidVector(containedType, items))
            
        case .record:
            let rowTypes = type.keyedContainerRowTypes!
            var dictionary: [Int: CandidValue] = [:]
            for rowType in rowTypes {
                dictionary[rowType.hashedKey] = try decodeValue(rowType.type, stream)
            }
            return .record(CandidDictionary(dictionary))
            
        case .variant:
            let rowTypes = type.keyedContainerRowTypes!
            let valueIndex: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
            return .variant(CandidVariant(
                candidTypes: rowTypes,
                value: try decodeValue(rowTypes[valueIndex].type, stream),
                valueIndex: UInt(valueIndex)
            ))
            
        case .function:
            let isPresent = try stream.readNextByte() == 1
            let serviceMethod: CandidFunction.ServiceMethod?
            if isPresent {
                guard try stream.readNextByte() == 1 else {
                    throw CandidDeserialisationError.invalidTypeReference
                }
                let principalIdLength: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
                let principalId = try stream.readNextBytes(principalIdLength)
                
                let nameLength: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
                let nameData = try stream.readNextBytes(nameLength)
                guard let name = String(data: nameData, encoding: .utf8) else {
                    throw CandidDeserialisationError.invalidUtf8String
                }
                
                serviceMethod = CandidFunction.ServiceMethod(name: name, principalId: principalId)
                
            } else {
                serviceMethod = nil
            }
            return .function(CandidFunction(
                signature: type.functionSignature!,
                method: serviceMethod
            ))
            
            
//        case .service:
//            let isPresent = try stream.readNextByte() == 1
//            let principalId: Data?
//            if isPresent {
//                let principalIdLength: Int = try ICPCryptography.Leb128.decodeUnsigned(stream)
//                principalId = try stream.readNextBytes(principalIdLength)
//            } else {
//                principalId = nil
//            }
//            return .service(CandidService(
//                methods: type.serviceMethods!,
//                principalId: principalId
//            ))
        }
        
    }
}

private extension CandidType {
    var primitiveType: CandidPrimitiveType {
        switch self {
        case .primitive(let primitive),
             .container(let primitive, _),
             .keyedContainer(let primitive, _): return primitive
        case .function: return .function
        //case .service: return .service
        }
    }
    
    var containedType: CandidType? {
        guard case .container(_, let type) = self else { return nil }
        return type
    }
    
    var keyedContainerRowTypes: [CandidDictionaryItemType]? {
        guard case .keyedContainer(_, let rowTypes) = self else { return nil }
        return rowTypes
    }
    
    var functionSignature: CandidFunctionSignature? {
        guard case .function(let candidFunctionSignature) = self else { return nil }
        return candidFunctionSignature
    }
    
//    var serviceMethods: [CandidService.Method]? {
//        guard case .service(let methods) = self else { return nil }
//        return methods
//    }
}
