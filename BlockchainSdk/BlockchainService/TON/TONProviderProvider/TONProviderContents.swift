//
//  TONProviderContent.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// TON provider content of Response
struct TONProviderContent {
    
    /// Account state model
    enum AccountState: String, Codable {
        case active
        case uninitialized
    }
    
    /// Info state model
    struct Info: Codable {
        
        /// Is chain transaction wallet
        let wallet: Bool
        
        /// Balance in string value
        let balance: String
        
        /// State of wallet
        let account_state: AccountState
        
        /// Sequence number transations
        let seqno: Int?
        
        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<TONProviderContent.Info.CodingKeys> = try decoder.container(keyedBy: TONProviderContent.Info.CodingKeys.self)
            self.wallet = try container.decode(Bool.self, forKey: TONProviderContent.Info.CodingKeys.wallet)
            self.balance = try Self.mapBalance(from: decoder)
            self.account_state = try container.decode(TONProviderContent.AccountState.self, forKey: TONProviderContent.Info.CodingKeys.account_state)
            self.seqno = try container.decodeIfPresent(Int.self, forKey: TONProviderContent.Info.CodingKeys.seqno)
        }
        
        // MARK: - Info Private Implementation
        
        private static func mapBalance(from decoder: Decoder) throws -> String {
            let container: KeyedDecodingContainer<TONProviderContent.Info.CodingKeys> = try decoder.container(keyedBy: TONProviderContent.Info.CodingKeys.self)
            let strValue = try? container.decode(String.self, forKey: TONProviderContent.Info.CodingKeys.balance)
            let intValue = try? container.decode(Int.self, forKey: TONProviderContent.Info.CodingKeys.balance)
            return strValue ?? String(intValue ?? 0)
        }
        
    }
    
    /// Fee agregate model
    struct Fee: Codable {
        
        struct SourceFees: Codable {
            
            /// Is a charge for importing messages from outside the blockchain.
            /// Every time you make a transaction, it must be delivered to the validators who will process it.
            let in_fwd_fee: Decimal
            
            /// Is the amount you pay for storing a smart contract in the blockchain.
            /// In fact, you pay for every second the smart contract is stored on the blockchain.
            let storage_fee: Decimal
            
            /// Is the amount you pay for executing code in the virtual machine.
            /// The larger the code, the more fees must be paid.
            let gas_fee: Decimal
            
            /// Stands for a charge for sending messages outside the TON
            let fwd_fee: Decimal
            
            // MARK: - Helper
            
            var allFee: Decimal {
                in_fwd_fee + storage_fee + gas_fee + fwd_fee
            }
            
        }
        
        // MARK: - Properties
        
        /// Fees model
        let source_fees: SourceFees
        
    }
    
    /// Response decode send boc model
    struct SendBoc: Codable {}
    
    /// Sequence number model
    struct Seqno: Codable {
        
        struct Stack: Codable {
            let num: String
        }
        
        // MARK: - Properties
        
        /// Container seqno number
        let stack: [[Stack]]
        
    }

    
}
