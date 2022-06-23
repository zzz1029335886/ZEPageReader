//
//  AppDelegate.swift
//  ZEPageReader
//
//  Created by zerry on 2022/6/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        self.window = .init(frame: UIScreen.main.bounds)
        self.window?.makeKeyAndVisible()
        
        let con = ViewController()
        self.window?.rootViewController = con
        
        
        return true
    }



}

