# Tron Protobuf

Tron.proto is taken from here:
https://github.com/tronprotocol/protocol/blob/master/core

Contracts.proto is a compilation consistent of protobufs from the following files:
https://github.com/tronprotocol/protocol/blob/master/core/contract/balance_contract.proto
https://github.com/tronprotocol/protocol/blob/master/core/contract/smart_contract.proto

Note that the 'package' property was changed from 'protocol' to 'tron' to make the names of generated objects less ambiguous in the context of this SDK.

The WalletCore's protobuf files do not have the Transaction message, that's why the Tron sources were picked.
