// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: core/contract/witness_contract.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Protocol_WitnessCreateContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var url: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Protocol_WitnessUpdateContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var updateURL: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Protocol_VoteWitnessContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var votes: [Protocol_VoteWitnessContract.Vote] = []

  var support: Bool = false

  var unknownFields = SwiftProtobuf.UnknownStorage()

  struct Vote: @unchecked Sendable {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    var voteAddress: Data = Data()

    var voteCount: Int64 = 0

    var unknownFields = SwiftProtobuf.UnknownStorage()

    init() {}
  }

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "protocol"

extension Protocol_WitnessCreateContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".WitnessCreateContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .same(proto: "url"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.url) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if !self.url.isEmpty {
      try visitor.visitSingularBytesField(value: self.url, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_WitnessCreateContract, rhs: Protocol_WitnessCreateContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.url != rhs.url {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_WitnessUpdateContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".WitnessUpdateContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    12: .standard(proto: "update_url"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 12: try { try decoder.decodeSingularBytesField(value: &self.updateURL) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if !self.updateURL.isEmpty {
      try visitor.visitSingularBytesField(value: self.updateURL, fieldNumber: 12)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_WitnessUpdateContract, rhs: Protocol_WitnessUpdateContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.updateURL != rhs.updateURL {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_VoteWitnessContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".VoteWitnessContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .same(proto: "votes"),
    3: .same(proto: "support"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.votes) }()
      case 3: try { try decoder.decodeSingularBoolField(value: &self.support) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if !self.votes.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.votes, fieldNumber: 2)
    }
    if self.support != false {
      try visitor.visitSingularBoolField(value: self.support, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_VoteWitnessContract, rhs: Protocol_VoteWitnessContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.votes != rhs.votes {return false}
    if lhs.support != rhs.support {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_VoteWitnessContract.Vote: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = Protocol_VoteWitnessContract.protoMessageName + ".Vote"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "vote_address"),
    2: .standard(proto: "vote_count"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.voteAddress) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.voteCount) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.voteAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.voteAddress, fieldNumber: 1)
    }
    if self.voteCount != 0 {
      try visitor.visitSingularInt64Field(value: self.voteCount, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_VoteWitnessContract.Vote, rhs: Protocol_VoteWitnessContract.Vote) -> Bool {
    if lhs.voteAddress != rhs.voteAddress {return false}
    if lhs.voteCount != rhs.voteCount {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
