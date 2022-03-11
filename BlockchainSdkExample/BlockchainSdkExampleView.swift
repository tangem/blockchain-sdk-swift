//
//  BlockchainSdkExampleView.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BlockchainSdkExampleView: View {
    @EnvironmentObject var model: BlockchainSdkExampleViewModel
    
    var body: some View {
        NavigationView {
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
                    .modifier(PickerStyleModifier())
                    
                    if model.blockchainsWithCurveSelection.contains(model.blockchainName) {
                        Picker("Curve", selection: $model.curve) {
                            ForEach(model.curves, id: \.self) { curve in
                                Text(curve.rawValue)
                                    .tag(curve.rawValue)
                            }
                        }
                        .disabled(model.card == nil)
                        .modifier(PickerStyleModifier())
                    }
                    
                    Toggle("Testnet", isOn: $model.isTestnet)
                        .disabled(model.card == nil)
                    
                    if model.blockchainsWithShelleySelection.contains(model.blockchainName) {
                        Toggle("Shelley", isOn: $model.isShelley)
                            .disabled(model.card == nil)
                    }
                }
                
                Section(header: Text("Source address and balance")) {
                    if model.sourceAddresses.isEmpty {
                        Text("--")
                    } else {
                        ForEach(model.sourceAddresses, id: \.value) { address in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(address.type.localizedName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(address.value)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Spacer()
                                
                                Button {
                                    model.copySourceAddressToClipboard(address)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Text(model.balance)
                            .modifier(TextSelectionConditionalModifier())
                        
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
                    
                    if model.feeDescriptions.isEmpty {
                        Text("--")
                    } else {
                        ForEach(model.feeDescriptions, id: \.self) {
                            Text($0)
                        }
                    }                    
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
            .navigationBarTitle("Blockchain SDK")
            .onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }
        }
    }
}

fileprivate struct PickerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content
                .pickerStyle(.menu)
        } else {
            content
                .pickerStyle(.automatic)
        }
    }
}

fileprivate struct TextSelectionConditionalModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .textSelection(.enabled)
        } else {
            content
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
