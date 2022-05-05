# Tron Protobuf

Tron.proto is taken from here:
https://github.com/tronprotocol/protocol/blob/master/core

Contracts.proto is a compilation consistent of protobufs from the following files:
https://github.com/tronprotocol/protocol/blob/master/core/contract/balance_contract.proto
https://github.com/tronprotocol/protocol/blob/master/core/contract/smart_contract.proto

DO NOT rename the 'package' property. If you do the serialisation will change and the runtime will stop accepting the transactions.

The WalletCore's protobuf files do not have the Transaction message, that's why the Tron sources were picked.
