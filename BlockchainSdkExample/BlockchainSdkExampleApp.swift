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
    
    var provider: ElectrumNetworkProvider? = ElectrumNetworkProvider(
        providers: [
            "wss://onekey-electrum.bitcoinunlimited.info:20004",
//            "wss://electrum.nexa.org:20004"
        ].map { .init(url: URL(string: $0)!) },
        decimalValue: 1 //pow(10,8)
    )
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let contentView = BlockchainSdkExampleView()
            .environmentObject(model)
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        
        self.bag = provider?
            .getAddressInfo(address: "nexa:nqtsq5g5rxlm4e6lc8aszkx7gfaftfxxs7mrex7367kj6ny6")
            .sink { _ in } receiveValue: { value in
                print("getAddressInfo", value)
                self.provider = nil
            }
        
//        self.bag = provider?
//            .getAddressInfo(address: "nexa:nqtsq5g5rxlm4e6lc8aszkx7gfaftfxxs7mrex7367kj6ny6")
//            .delay(for: 15, scheduler: DispatchQueue.global())
//            .flatMap({ _ in
//                print("AddressInfo")
//                return self.provider?.estimateFee()
//            })
//            .sink { _ in } receiveValue: { value in
//                print("Success")
//                self.provider = nil
//            }
        
//        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//            self.provider = nil
//        }
        
        return true
    }
}
