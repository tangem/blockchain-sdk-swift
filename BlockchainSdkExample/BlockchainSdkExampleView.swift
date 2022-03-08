//
//  BlockchainSdkExampleView.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemSdk

struct BlockchainSdkExampleView: View {
    let sdk = TangemSdk()
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
                .onAppear {
                    let b = Blockchain.ducatus
                    print(b)
                }
            
            Button {
                sdk.scanCard(initialMessage: nil) { result in
                    print(result)
                }
            } label: {
                Text("Scan card")
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
