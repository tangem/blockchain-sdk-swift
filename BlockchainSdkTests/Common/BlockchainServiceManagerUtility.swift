//
//  BlockchainServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 19.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

final class BlockchainServiceManagerUtility {
    
    let blockchains: [BlockchainSdk.Blockchain] = [
        Blockchain.bitcoin(testnet: false),
        Blockchain.litecoin,
        Blockchain.stellar(testnet: false),
        Blockchain.ethereum(testnet: false),
        Blockchain.ethereumPoW(testnet: false),
        Blockchain.ethereumFair,
        Blockchain.ethereumClassic(testnet: false),
        Blockchain.rsk,
        Blockchain.bitcoinCash(testnet: false),
        Blockchain.binance(testnet: false),
        Blockchain.cardano(shelley: true),
        Blockchain.xrp(curve: .secp256k1),
        Blockchain.tezos(curve: .ed25519),
        Blockchain.dogecoin,
        Blockchain.bsc(testnet: false),
        Blockchain.polygon(testnet: false),
        Blockchain.avalanche(testnet: false),
        Blockchain.solana(testnet: false),
        Blockchain.fantom(testnet: false),
        Blockchain.polkadot(testnet: false),
        Blockchain.kusama,
        Blockchain.tron(testnet: false),
        Blockchain.arbitrum(testnet: false),
        Blockchain.dash(testnet: false),
        Blockchain.gnosis,
        Blockchain.optimism(testnet: false),
        Blockchain.ton(testnet: false),
        Blockchain.kava(testnet: false),
        Blockchain.kaspa,
        Blockchain.ravencoin(testnet: false),
    ]
    
    let sdkDerivations: [DerivationUnion] = [
        .init(path: "m/44'/0'/0'/0/0", blockchain: .bitcoin(testnet: false)),
        .init(path: "m/44'/2'/0'/0/0", blockchain: .litecoin),
        .init(path: "m/44'/148'/0'", blockchain: .stellar(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereum(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereumPoW(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereumFair),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereumClassic(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .rsk),
        .init(path: "m/44'/145'/0'/0/0", blockchain: .bitcoinCash(testnet: false)),
        .init(path: "m/44'/714'/0'/0/0", blockchain: .binance(testnet: false)),
        .init(path: "m/1852'/1815'/0'/0/0", blockchain: .cardano(shelley: true)),
        .init(path: "m/44'/144'/0'/0/0", blockchain: .xrp(curve: .secp256k1)),
        .init(path: "m/44'/1729'/0'/0/0", blockchain: .tezos(curve: .ed25519)),
        .init(path: "m/44'/3'/0'/0/0", blockchain: .dogecoin),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .bsc(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .polygon(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .avalanche(testnet: false)),
        .init(path: "m/44'/501'/0'", blockchain: .solana(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .fantom(testnet: false)),
        .init(path: "m/44'/354'/0'/0/0", blockchain: .polkadot(testnet: false)),
        .init(path: "m/44'/434'/0'/0/0", blockchain: .kusama),
        .init(path: "m/44'/195'/0'/0/0", blockchain: .tron(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .arbitrum(testnet: false)),
        .init(path: "m/44'/5'/0'/0/0", blockchain: .dash(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .gnosis),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .optimism(testnet: false)),
        .init(path: "m/44'/607'/0'/0/0", blockchain: .ton(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .kava(testnet: false)),
        .init(path: "m/44'/111111'/0'/0/0", blockchain: .kaspa),
        .init(path: "m/44'/175'/0'/0/0", blockchain: .ravencoin(testnet: false)),
    ]
    
    let twDerivations: [DerivationUnion] = [
        .init(path: "m/84'/0'/0'/0/0", blockchain: .bitcoin(testnet: false)),
        .init(path: "m/84'/2'/0'/0/0", blockchain: .litecoin),
        .init(path: "m/44'/148'/0'", blockchain: .stellar(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereum(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereumPoW(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .ethereumFair),
        .init(path: "m/44'/61'/0'/0/0", blockchain: .ethereumClassic(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .rsk),
        .init(path: "m/44'/145'/0'/0/0", blockchain: .bitcoinCash(testnet: false)),
        .init(path: "m/44'/714'/0'/0/0", blockchain: .binance(testnet: false)),
        .init(path: "m/1852'/1815'/0'/0/0", blockchain: .cardano(shelley: true)), // посмотреть true
        .init(path: "m/44'/144'/0'/0/0", blockchain: .xrp(curve: .secp256k1)),
        .init(path: "m/44'/1729'/0'/0/0", blockchain: .tezos(curve: .ed25519)),
        .init(path: "m/44'/3'/0'/0/0", blockchain: .dogecoin),
        .init(path: "m/44'/714'/0'/0/0", blockchain: .bsc(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .polygon(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .avalanche(testnet: false)),
        .init(path: "m/44'/501'/0'", blockchain: .solana(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .fantom(testnet: false)),
        .init(path: "m/44'/354'/0'/0'/0'", blockchain: .polkadot(testnet: false)),
        .init(path: "m/44'/434'/0'/0'/0'", blockchain: .kusama),
        .init(path: "m/44'/195'/0'/0/0", blockchain: .tron(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .arbitrum(testnet: false)),
        .init(path: "m/44'/5'/0'/0/0", blockchain: .dash(testnet: false)),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .gnosis),
        .init(path: "m/44'/60'/0'/0/0", blockchain: .optimism(testnet: false)),
        .init(path: "m/44'/607'/0'", blockchain: .ton(testnet: false)),
        .init(path: "m/44'/459'/0'/0/0", blockchain: .kava(testnet: false)),
        .init(path: "m/44'/111111'/0'/0/0", blockchain: .kaspa),
        .init(path: "m/44'/175'/0'/0/0", blockchain: .ravencoin(testnet: false)),
    ]
    
    /*
     List of mnemonics for testing
     https://docs.google.com/spreadsheets/d/12c-mn4aCKc_Mf6vtKusxgYlE0BRV-pZvfimkMYNXrfg/edit#gid=0
     */
    let mnemonics = [
        "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
    ]
    
    /*
     List of addresses from TrustWallet HDWallet for: "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
     */
    let twAddressesMnemonicWithDerivation: [AddressUnion] = [
        .init(address: "bc1qnvhettk30ch9j0c64cldwthktmd66w9xhyytgq", blockchain: .bitcoin(testnet: false)),
        .init(address: "ltc1qw0lem6vgtpgq2xffsqdw22dd7epzfz6e39wld9", blockchain: .litecoin),
        .init(address: "GCFW7Y6DNIP3LEYMACPWWIZB3L5UIIE2R3ZSKU3HFYZZULTO7UZKYSKI", blockchain: .stellar(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .ethereum(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .ethereumClassic(testnet: false)),
        .init(address: "bitcoincash:qqml0kr5t7eer7qrsnzvxa0xazzwun8v9q44km8zsn", blockchain: .bitcoinCash(testnet: false)),
        .init(address: "bnb1at6qa8typl6hkvtgrh6pn2ll33ypwhnn5mut87", blockchain: .binance(testnet: false)),
        .init(address: "tz1VS7w9rWmt7e4n3DeyGKwVZ8rGgzSwupYM", blockchain: .tezos(curve: .ed25519)),
        .init(address: "DEgYuoZXK4NeTg2t6Nhe7935onC13x1hGE", blockchain: .dogecoin),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .bsc(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .polygon(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .avalanche(testnet: false)),
        .init(address: "9HPwXfkjEH3UvV4vJeCMuyZDNGf8xTEqUrfutokiSD39", blockchain: .solana(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .fantom(testnet: false)),
        .init(address: "1UnMR5Vtwdm8b1UkzE28RvLb3zU2qVQrGypzQpTneyM66a5", blockchain: .polkadot(testnet: false)),
        .init(address: "HDrjj5cNgZSGe71Ex3unUBir4tfWagwAyUZv1or3ofBDcNV", blockchain: .kusama),
        .init(address: "TQmXHQ839u7eZEwhEnshWmc8yHYkGYQmqy", blockchain: .tron(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .arbitrum(testnet: false)),
        .init(address: "XrJYTTgJt4jgEst2uqskiAzHdjY13YQCdh", blockchain: .dash(testnet: false)),
        .init(address: "0x5984781A30B49B5E9b835278b08ACf296DF6874d", blockchain: .optimism(testnet: false)),
        .init(address: "EQBFqL_6IC03p3LZ8PSCxLTOIkKwU0X9INBJhY55F-EU9gVT", blockchain: .ton(testnet: false)),
        .init(address: "kava1uf66vvezgmzwql0qjgdtl8pdkm8zseem8mwrr7", blockchain: .kava(testnet: false)),
        .init(address: "RPTqwXzy7LmMLbPWdDE4yP3QBThMJij3ZY", blockchain: .ravencoin(testnet: false)),
    ]
    
    /*
     List of PublicKeys from TangemSdk HDWallet for: "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
     */
    let sdkPublicKeysFromMnemonic: [PublicKeyUnion] = [
        .init(key: "032A08567430A46A47CFFBF3FFD7FBB17A7850E75E7AC8E3E034BB1D8D5625A30D", blockchain: .bitcoin(testnet: false)),
        .init(key: "0361607CC77FF2AF9C985C7E3791E8209E0F274B243CF81D9932E8C6A014A0F9F0", blockchain: .litecoin),
        .init(key: "C42FFE4F0EC064D0324E6018BE66A053C0F0BF50B01FCA3646FBC160656285C0", blockchain: .stellar(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .ethereum(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .ethereumPoW(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .ethereumFair),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .ethereumClassic(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .rsk),
        .init(key: "03D6FDE463A4D0F4DECC6AB11BE24E83C55A15F68FD5DB561EEBCA021976215FF5", blockchain: .bitcoinCash(testnet: false)),
        .init(key: "03A17B33F13B894BF46FE4BB0E060F8F6A7A79B9556B910629FE7CDF4CF91DBC04", blockchain: .binance(testnet: false)),
        .init(key: "5A3C15C97EE6632CB113F3A4E6465C93CBEA3E5A77E4CB063C5501FBE92C072B", blockchain: .cardano(shelley: true)),
        .init(key: "0393F5CD6F5FFB5DB412218815FE3210D97C6E1994517D127382488FF3ACF2758A", blockchain: .xrp(curve: .secp256k1)),
        .init(key: "0372B211C46A7D9F7428D237A17DFBF27ABA664FE8E55FA73B48B45C10C3543897", blockchain: .tezos(curve: .ed25519)),
        .init(key: "03149EA0300DBB38AA8DF2C00E8EAA7C586B6FA697BD9CA1AA06344266AC96A528", blockchain: .dogecoin),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .bsc(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .polygon(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .avalanche(testnet: false)),
        .init(key: "034D2D2A3F4A2099FDC9414607706F6C8F1B4C7439002C256CB12CE4AF90D3FE", blockchain: .solana(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .fantom(testnet: false)),
        .init(key: "0BA9AB99A3A07ED502CB14A35CDBE92F5882AC1B690E8AFA195F98121FB4FC3D", blockchain: .polkadot(testnet: false)),
        .init(key: "6E19C225663EEDB1BB3786DBBB262B7172141947317FFD1A97E0AA6F4380BCF0", blockchain: .kusama),
        .init(key: "0246A5F0CA01A7018E7B4C11734F610483FE694947559BD6CB6A157FE23C752A64", blockchain: .tron(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .arbitrum(testnet: false)),
        .init(key: "02AF38CA8890E8C46FA63C5B1DAA36371AC59DB5DB5BEC6968A1B5759927196E8E", blockchain: .dash(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .gnosis),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .optimism(testnet: false)),
        .init(key: "5D09117F61B9944546041D8DF5EECC1CEDFF325D12C17DB10B495245AB93F9A5", blockchain: .ton(testnet: false)),
        .init(key: "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56", blockchain: .kava(testnet: false)),
        .init(key: "035F25F3544EF2D031DB235B341112C31F1B26C03F13DC52B5D0E2D508A4F3F176", blockchain: .kaspa),
        .init(key: "0260BF54E0D66880E36FC5400C5CBF799AE129807B03B0FC88DB2506217EB24D85", blockchain: .ravencoin(testnet: false)),
    ]
    
}

extension BlockchainServiceManagerUtility {
    
    public struct DerivationUnion: CustomDebugStringConvertible {
        let path: String
        let blockchain: BlockchainSdk.Blockchain
        
        public var debugDescription: String {
            "blockchain: \(blockchain.currencySymbol)"
        }
    }
    
    public struct AddressUnion {
        let address: String
        let blockchain: BlockchainSdk.Blockchain
    }
    
    public struct PublicKeyUnion {
        let key: String
        let blockchain: BlockchainSdk.Blockchain
    }
    
}
