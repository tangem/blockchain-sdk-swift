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
                .disabled(model.card == nil)
                .pickerStyle(.menu)
                
                if model.blockchainsWithCurveSelection.contains(model.blockchainName) {
                    Picker("Curve", selection: $model.curve) {
                        ForEach(model.curves, id: \.self) { curve in
                            Text(curve.rawValue)
                                .tag(curve.rawValue)
                        }
                    }
                    .disabled(model.card == nil)
                    .pickerStyle(.menu)
                }
                
                Toggle("Testnet", isOn: $model.isTestnet)
                    .disabled(model.card == nil)
                
                if model.blockchainsWithShelleySelection.contains(model.blockchainName) {
                    Toggle("Shelley", isOn: $model.isShelley)
                        .disabled(model.card == nil)
                }
            }
            
            Section(header: Text("Source address and balance")) {
                Text(model.sourceAddress)
                    .textSelection(.enabled)
                
                HStack {
                    Text(model.balance)
                        .textSelection(.enabled)
                    
                    Spacer()

                    Button {
                        model.updateBalance()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            
            Section(header: Text("Destination and amount to send")) {
                TextField("Destination", text: $model.destination)
                    .disableAutocorrection(true)
                    .keyboardType(.alphabet)
                    .truncationMode(.middle)
                
                TextField("Amount", text: $model.amountToSend)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("Fees")) {
                Button {
                    model.checkFee()
                } label: {
                    Text("Check fee")
                }
                
                Text(model.feeDescription)
            }
            .disabled(model.walletManager == nil)
            
            Section(header: Text("Transaction")) {
                Button {
                    model.sendTransaction()
                } label: {
                    Text("Send transaction")
                }
                
                Text(model.transactionResult)
            }
            .disabled(model.walletManager == nil)
        }
        .onAppear {
            UIScrollView.appearance().keyboardDismissMode = .onDrag
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
