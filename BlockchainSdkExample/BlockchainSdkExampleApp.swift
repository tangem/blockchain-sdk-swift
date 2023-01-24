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
        let wallet = try! TONWallet(publicKey: Data(hexString: "995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b"))
        let addr = try! wallet.getAddress()
        
        print(addr.toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true))
        
        try! wallet.createTransferMessage(
            address: "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2",
            amount: 100,
            payload: nil,
            seqno: 324,
            expireAt: UInt64()
        )
        
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
