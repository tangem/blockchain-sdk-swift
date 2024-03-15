//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import BlockchainSdk
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let model = BlockchainSdkExampleViewModel()
    var bag: AnyCancellable?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let contentView = BlockchainSdkExampleView()
            .environmentObject(model)
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        
        let nexaURLs: [String] = [
            "wss://onekey-electrum.bitcoinunlimited.info:20004",
//            "wss://electrum.nexa.org:20004"
        ]
        
        let provider = ElectrumNetworkProvider(
            providers: nexaURLs.map { .init(url: URL(string: $0)!) },
            decimalValue: 1 //pow(10,8)
        )
        
        self.bag = Publishers.Zip(
            provider.getBalance(address: "nexa:nqtsq5g5rxlm4e6lc8aszkx7gfaftfxxs7mrex7367kj6ny6"),
            provider.getUnspents(address: "nexa:nqtsq5g5rxlm4e6lc8aszkx7gfaftfxxs7mrex7367kj6ny6")
        )
        .print()
        .sink { _ in } receiveValue: { _ in }
        
        return true
    }
}
