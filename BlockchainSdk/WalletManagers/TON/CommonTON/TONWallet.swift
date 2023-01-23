//
//  TONWallet.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation

private let CellBocWallet = "B5EE9C72410214010002D4000114FF00F4A413F4BCF2C80B010201200203020148040504F8F28308D71820D31FD31FD31F02F823BBF264ED44D0D31FD31FD3FFF404D15143BAF2A15151BAF2A205F901541064F910F2A3F80024A4C8CB1F5240CB1F5230CBFF5210F400C9ED54F80F01D30721C0009F6C519320D74A96D307D402FB00E830E021C001E30021C002E30001C0039130E30D03A4C8CB1F12CB1FCBFF1011121302E6D001D0D3032171B0925F04E022D749C120925F04E002D31F218210706C7567BD22821064737472BDB0925F05E003FA403020FA4401C8CA07CBFFC9D0ED44D0810140D721F404305C810108F40A6FA131B3925F07E005D33FC8258210706C7567BA923830E30D03821064737472BA925F06E30D06070201200809007801FA00F40430F8276F2230500AA121BEF2E0508210706C7567831EB17080185004CB0526CF1658FA0219F400CB6917CB1F5260CB3F20C98040FB0006008A5004810108F45930ED44D0810140D720C801CF16F400C9ED540172B08E23821064737472831EB17080185005CB055003CF1623FA0213CB6ACB1FCB3FC98040FB00925F03E20201200A0B0059BD242B6F6A2684080A06B90FA0218470D4080847A4937D29910CE6903E9FF9837812801B7810148987159F31840201580C0D0011B8C97ED44D0D70B1F8003DB29DFB513420405035C87D010C00B23281F2FFF274006040423D029BE84C600201200E0F0019ADCE76A26840206B90EB85FFC00019AF1DF6A26840106B90EB858FC0006ED207FA00D4D422F90005C8CA0715CBFFC9D077748018C8CB05CB0222CF165005FA0214CB6B12CCCCC973FB00C84014810108F451F2A7020070810108D718FA00D33FC8542047810108F451F2A782106E6F746570748018C8CB05CB025006CF165004FA0214CB6A12CB1FCB3FC973FB0002006C810108D718FA00D33F305224810108F459F2A782106473747270748018C8CB05CB025005CF165003FA0213CB6ACB1F12CB3FC973FB00000AF400C9ED54696225E5"

private let CellWalletId = "698983191"

public class TONWallet: TONContract {
    
    /// Публичный ключ кошелька
    var publicKey: Data
    
    // MARK: - Init
    
    public init(publicKey: Data, walletId: String? = nil, wc: Int = 0) throws {
        self.publicKey = publicKey
        
        try super.init(
            options: .init(
                code: TONCell.oneFromBoc(Data(hexString: CellBocWallet).bytes),
                address: nil,
                walletId: walletId ?? CellWalletId + String(wc),
                wc: wc
            )
        )
    }
    
    override func createDataCell() throws -> TONCell {
        let cell = TONCell()
        try cell.raw.write(uint: 0, 32)
        try cell.raw.write(bits: Int32(CellWalletId)!.bits.reversed())
        try cell.raw.write(bytes: publicKey.bytes)
        try cell.raw.write(uint: 0, 1)
        return cell
    }
    
    /**
     * @param secretKey {Uint8Array}  nacl.KeyPair.secretKey
     * @param address   {Address | string}
     * @param amount    {BN | number} in nanograms
     * @param seqno {number}
     * @param payload?   {string | Uint8Array | Cell}
     * @param sendMode?  {number}
     * @param dummySignature?    {boolean}
     * @param stateInit? {Cell}
     * @param expireAt? {number}
     * @return {Promise<{address: Address, signature: Uint8Array, message: Cell, cell: Cell, body: Cell, resultMessage: Cell}>}
     */
    func createTransferMessage(
        address: String,
        amount: Int,
        seqno: Int,
        sendMode: Int = 3,
        dummySignature: Bool = false,
        stateInit: TONCell? = nil,
        expireAt: UInt64
    ) throws {
        let payloadCell = TONCell()
        
        let orderHeader = try TONContract.createInternalMessageHeader(
            dest: address,
            src: self.address!.toString()
        )
    }
    
    /**
     * @protected
     * @param   seqno?   {number}
     * @return {Cell}
     */
    func createSigningMessage(seqno: Int?) throws -> TONCell {
        let seqno = seqno == nil ? 0 : seqno!
        let cell = TONCell()
        try cell.raw.write(int: seqno, 32)
        return cell
    }
    
}
