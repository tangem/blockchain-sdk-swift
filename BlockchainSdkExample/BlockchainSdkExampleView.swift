//
//  BlockchainSdkExampleView.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BlockchainSdkExampleView: View {
    @StateObject var model = BlockchainSdkExampleViewModel()
    
    var body: some View {
        Form {
            Section {
                Button {
                    model.scanCardAndGetInfo()
                } label: {
                    Text("Scan card")
                }
                
                Picker("Blockchain", selection: $model.blockchainName) {
                    Text("Not selected").tag("")
                    ForEach(model.blockchains, id: \.1) { blockchain in
                        Text(blockchain.0)
                            .tag(blockchain.1)
                    }
                }
                .disabled(model.transactionSender == nil)
                .pickerStyle(.menu)
                
                Picker("Curve", selection: $model.curve) {
                    ForEach(model.curves, id: \.self) { curve in
                        Text(curve.rawValue)
                            .tag(curve.rawValue)
                    }
                }
                .disabled(model.transactionSender == nil)
                .pickerStyle(.menu)
                
                Toggle("Testnet", isOn: $model.isTestnet)
                    .disabled(model.transactionSender == nil)
                
                Toggle("Shelley", isOn: $model.isShelley)
                    .disabled(model.transactionSender == nil)
            }
            
            Section("Source address") {
                Text(model.sourceAddress)
                    .textSelection(.enabled)
            }
            
            Section("Destination and amount") {
                TextField("Destination", text: $model.destination)
                    .disableAutocorrection(true)
                    .keyboardType(.alphabet)
                    .truncationMode(.middle)
                
                TextField("Amount", text: $model.amountToSend)
                    .keyboardType(.decimalPad)
            }
            
            Section("Fees") {
                Button {
                    model.checkFee()
                } label: {
                    Text("Check fee")
                }
                
                Text(model.feeDescription)
            }
            .disabled(model.transactionSender == nil)
            
            Section("Transaction") {
                Button {
                    model.sendTransaction()
                } label: {
                    Text("Send transaction")
                }
                
                Text(model.transactionResult)
            }
            .disabled(model.transactionSender == nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
