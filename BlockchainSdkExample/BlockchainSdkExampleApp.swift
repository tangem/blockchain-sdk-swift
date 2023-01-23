//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import TangemSdk
import BlockchainSdk

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let model = BlockchainSdkExampleViewModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let wallet = try! TONWallet(publicKey: Data(hexString: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5"))
        let addr = try! wallet.getAddress()
        print(addr.toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true))
        print("----")
        
//        let contentView = BlockchainSdkExampleView()
//            .environmentObject(model)
//
//        let window = UIWindow()
//        window.rootViewController = UIHostingController(rootView: contentView)
//        self.window = window
//        window.makeKeyAndVisible()

        return true
    }
}
