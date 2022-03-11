//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let model = BlockchainSdkExampleViewModel()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = BlockchainSdkExampleView()
            .environmentObject(model)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
