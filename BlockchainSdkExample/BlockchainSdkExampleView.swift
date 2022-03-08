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
                
                TextField("Destination", text: $model.destination)
                    .disableAutocorrection(true)
                    .keyboardType(.alphabet)
                
                TextField("Amount", text: $model.amountToSend)
                    .keyboardType(.decimalPad)
            }
            
            Section {
                Button {
                    model.checkFee()
                } label: {
                    Text("Check fee")
                }
                .disabled(model.transactionSender == nil)
                
                Text("Fees: " + model.feeDescription)
            }
            
            Section {
                Button {
                    model.sendTransaction()
                } label: {
                    Text("Send transaction")
                }
                .disabled(model.transactionSender == nil)
                
                Text("TX result:" + model.transactionResult)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
