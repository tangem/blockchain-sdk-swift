//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import BigInt

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let model = BlockchainSdkExampleViewModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let contentView = BlockchainSdkExampleView()
            .environmentObject(model)
        
//        eg.    Int(-129) >> 7 = -2
//            BigInt(-129) >> 7 = -1   // should be -2
        
        let i1 = Int(-129) >> 7
        let i2 = BigInt(-129) >> 7
        
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

//extension BigInt {
//    func rightShiftFix<Other: BinaryInteger>(by other: Other) -> BigInt {
//        guard other >= (0 as any BinaryInteger) else { return self << (0 - other) }
//        return self >> other
//    }
//    
//    func leftShiftFix<Other: BinaryInteger>(by other: Other) -> BigInt {
//        
//    }
//}
