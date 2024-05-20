# ``BlockchainSdkTests``

This document describes the contents of the tests and the addition of new ones.

## Blockchains List



## Algorand

- ``WalletCore``
- ``Account, EdDSA, ed25519_slip0010``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |



## Aptos

- ``WalletCore``
- ``Account, Ed25519``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |



## Binance

- ``Account, ECDSA, secp256k1, SHA-256, BFT``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ⭕️ | For binance, it is necessary to add assert for not supported keys | |
| Common address validation positive & negative | ⭕️ | For binance, it is necessary to add address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | For binance, it is necessary to add transaction compiled | |
| Generate transaction for tokens currency ``buildForSend`` method | ⭕️ | For binance, it is necessary to add transaction compiled | |



## Bitcoin

- ``UTXO, ECDSA, secp256k1, SHA-256, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ⭕️ | For bitcoin, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | Legacy / Default | |
| Common address validation positive & negative | ⭕️ | For bitcoin, it is necessary to add address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Use TransactionSizeTesterUtility for testing size transaction UTXO | ✅ | | |



## BitcoinCash

- ``UTXO, ECDSA, secp256k1, SHA-256, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ⭕️ | For bitcoin, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | Legacy / Default | |
| Common address validation positive & negative | ⭕️ | For bitcoin, it is necessary to add address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | For BitcoinCash, it is necessary to add transaction compiled | |



## Cardano

- ``UTXO, EdDSA, ed25519 Extended, none, PoS``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ✅ | | |
| Any type address validation | ✅ | Legacy / Default addresses | |
| Common address validation positive & negative | ⭕️ | For Cardano, it is necessary to add address validation tests | |
| Any type address validation | ✅ | Legacy / Default | |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ⭕️ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | For Cardano, it is necessary to add transaction compiled | |
| Generate transaction for tokens currency ``buildForSend`` method | ⭕️ | For Cardano, it is necessary to add transaction compiled | |



## Chia

- ``UTXO, BLS Curve AUG scheme``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | For Chia, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Use TransactionSizeTesterUtility for testing size transaction UTXO | ✅ | | |



## Cosmos

- ``account, secp256k1, tokens``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | For Cosmos, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Generate transaction for tokens currency ``buildForSend`` method | ✅ | | |



## Dogecoin

- ``UTXO, secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Any type address validation | ✅ | | |
| Common address validation positive & negative | ⭕️ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |



## Ethereum

- ``Account, ECDSA, secp256k1, Keccak-256, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | For Ethereum, it is necessary to add assert for not supported keys | |
| Any type address validation | ⚠️ | Need more cases for testing | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Generate transaction for token currency ``buildForSend`` method | ✅ | | |



## Hedera

- ``DAG, Account, ECDSA/EdDSA, Ed25519 & secp256k1 (our implementation uses only Ed25519)``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | ``ed25519 / ed25519_slip0010`` | |
| Verify assert for not supported key | ⭕️ | For Hedera, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | ``ed25519 / ed25519_slip0010`` | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ⚠️ | Read comments in file | |
| Add raw valid_address_vectors.json | ⚠️ | | |
| Add raw blockchain_vectors.json | ⚠️ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |



## Kaspa

- ``UTXO, EDCSA. Technical limitation of no more than 84 inputs in a given transaction``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | For Kaspa, it is necessary to add assert for not supported keys | |
| Any type address validation | ⚠️ | Need more cases for testing in common AddressTests.swift | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | Read comments in file | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | ``P2SH / Schnorr`` | |



## Litecoin

- ``UTXO, ECDSA, secp256k1, SHA-256, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ⭕️ | For litecoin, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | ``Legacy / Default`` | |
| Common address validation positive & negative | ⭕️ | For litecoin, it is necessary to add more address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |



## NEAR

- ``Account, EdDSA, ed25519, none``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Done for compressed / decompressed keys | |
| Verify assert for not supported key | ⭕️ | For litecoin, it is necessary to add assert for not supported keys | |
| Any type address validation | ✅ | ``Legacy / Default`` | |
| Common address validation positive & negative | ⭕️ | For litecoin, it is necessary to add more address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |



## Optimism

- ``secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ⭕️ | Need insert generate address for key tests | |
| Verify assert for not supported key | ⭕️ | For litecoin, it is necessary to add assert for not supported keys | |
| Any type address validation | ⭕️ | | |
| Common address validation positive & negative | ⭕️ | For Optimism, it is necessary to add more address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ⭕️ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |



## Polkadot

- ``Account, ECDSA/EdDSA, secp256k1/ed25519/sr25519, blake2b, NPoS``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Exist test for Substrate chain Polkadot, Kusama, Westend, Azero | |
| Verify assert for not supported key | ⭕️ | For Polkadot, it is necessary to add assert for not supported keys | |
| Common address validation positive & negative | ⚠️ | For Polkadot, it is necessary to add more address validation tests | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |



## Radiant

- ``UTXO (BCH like) secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |



## Ravencoin

- ``UTXO, ECDSA, secp256k1, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | | |
| Common address validation positive & negative | ⭕️ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |



## Rsk

- ``Account, ECDSA, secp256k1, Keccak-256, PoW``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ⭕️ | | |
| Common address validation positive & negative | ⭕️ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |



## Solana

- ``-``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ⚠️ | Need more tests for blockchain | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |
| Generate transaction for token currency ``buildForSend`` method | ⭕️ | | |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |
| Use TransactionSizeTesterUtility for testing size transaction UTXO | ✅ | | |



## Stellar

- ``Account, EdDSA, ed25519, SHA-256, BFT``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ⚠️ | Need more tests for blockchain | |
| Validate address for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |



## Telos [EVM]

- ``No need implement any tests``



## Tezos

- ``Account, EdDSA, ed25519, none, PoS``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ⚠️ | Need more tests for blockchain | |
| Validate address for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | For Tezos, it is necessary to add transaction compiled | |



## TON

- ``Account, ECDSA/EdDSA, secp256k1/secp256r1/ed25519, BLAKE2, PoS``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Success verify any curves ``secp256k1/secp256r1/ed25519`` | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ⚠️ | Need more tests for blockchain | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Verify correct transaction for ``ed25519 / ed25519_slip0010`` curves | ✅ | | |



## Tron

- ``UTXO, ECDSA, secp256k1, SHA-256, DPoS``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Success verify curves ``secp256k1`` | |
| Verify assert for not supported key | ⭕️ | | |
| Common address validation positive & negative | ⚠️ | Need more tests for blockchain | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Generate transaction for token currency ``buildForSend`` method | ✅ | | |



## VeChain

- ``Account, secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Full completed address generation from key and convertation | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ✅ | | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Generate transaction for token currency ``buildForSend`` method | ✅ | | |



## XDC

- ``Account, secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Verify address converter | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ✅ | | |
| Generate transaction for token currency ``buildForSend`` method | ✅ | | |



## XRP

- ``Account, secp256k1``

### Common Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generation address from key | ✅ | Success verify any curves ``secp256k1/secp256r1/ed25519`` | |
| Verify assert for not supported key | ✅ | | |
| Common address validation positive & negative | ✅ | Need to add any positive / negative | |

### Vector Tests [Only WalletCore blockchain]

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Add raw trust_wallet_compare_vector.json | ✅ | | |
| Add raw valid_address_vectors.json | ✅ | | |
| Add raw blockchain_vectors.json | ✅ | | |

### Blockchain specify Tests

| Describe | Done | Comments | Task |
| -------- | ---- | ---------- | ---- |
| Generate transaction for network currency ``buildForSend`` method | ⭕️ | | |
