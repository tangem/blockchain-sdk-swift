//
//  TONProviderContent.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONProviderContent {
    
    enum AccountState: String, Codable {
        case active
        case uninitialized
    }
    
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
            self.balance = try container.decode(String.self, forKey: TONProviderContent.Info.CodingKeys.balance)
            self.account_state = try container.decode(TONProviderContent.AccountState.self, forKey: TONProviderContent.Info.CodingKeys.account_state)
            self.seqno = try container.decodeIfPresent(Int.self, forKey: TONProviderContent.Info.CodingKeys.seqno)
        }
        
    }

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

    struct SendBoc: Codable {}

    struct Seqno: Codable {
        
        struct Stack: Codable {
            let num: String
        }
        
        // MARK: - Properties
        
        /// Container seqno number
        let stack: [[Stack]]
        
    }

    
}
