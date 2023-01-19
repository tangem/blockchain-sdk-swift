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
        let wallet = try! TONWallet(publicKey: Data(hexString: "995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b"), wc: 0)
        let addr = try! wallet.getAddress()
        print(addr)
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
