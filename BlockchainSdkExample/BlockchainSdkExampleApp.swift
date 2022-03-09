//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

@main
struct BlockchainSdkExampleApp: App {
    var body: some Scene {
        WindowGroup {
            BlockchainSdkExampleView()
                .onAppear {
                    UIScrollView.appearance().keyboardDismissMode = .onDrag
                }
        }
    }
}
