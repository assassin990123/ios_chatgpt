//
//  AppDelegate.swift
//  chatGPTDemo
//
//  Created by hiren  mistry on 17/01/23.
//

import UIKit
let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
let appDelegate = UIApplication.shared.delegate as! AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        sleep(UInt32(1.5))
        if let vcLoginOp = self.viewController("ViewController", onStoryboard: "Main") as? ViewController {
                    let navigationController = UINavigationController(rootViewController: vcLoginOp)
                    navigationController.navigationBar.isHidden = true
                    self.window?.rootViewController = navigationController
                    self.window?.makeKeyAndVisible()
                }
        IQKeyboardManager.shared.enable = false
        IQKeyboardManager.shared.enableAutoToolbar = true
        UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }

    func viewController(_ name: String, onStoryboard storyboardName: String) -> UIViewController
    {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: name)
    }
    
    func showAlert(strMessage: String, vc: UIViewController) {
        let alert = UIAlertController(title: "Chat GPT", message: strMessage, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
}
