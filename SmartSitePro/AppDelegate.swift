//
//  AppDelegate.swift
//  SmartSitePro
//
//  Created by lijian on 2024/1/21.
//

import UIKit

// 维护升级的版本数字
let latestVersion = 2
// 极光推送的产品KEY，几乎不会改变
let JPUSH_KEY = "1bbe5d95adb5e12f8a1118ef"
// 弹框消息的广播
let jiGuang_alert_notification_name = "jiGuang_alert_notification_name"
// 跳转升级链接地址
let myAppStoreUrl = "itms-apps://itunes.apple.com/app/id6445959156"

// 生产链接
// let rootUrl: String = "http://hjkjgd.sinochemehc.com/app/#/login"
//
// 测试链接
let rootUrl: String = "http://172.16.95.239/app/#/login"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let entity = JPUSHRegisterEntity()
        entity.types = Int(JPAuthorizationOptions.alert.rawValue)
        JPUSHService.setup(withOption: launchOptions, appKey: JPUSH_KEY, channel: "App Store", apsForProduction: true)
        JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        //设置window的rootViewController
        self.window?.rootViewController = ViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("获取的deviceToken = \(deviceToken)")
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
}

extension AppDelegate: JPUSHRegisterDelegate {
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification) {
        print("openSettingsFor")
    }
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]?) {
        print("JPAuthorizationStatus")
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: ((Int) -> Void)) {
        JPushMsgManager.foregroundPushPageJump(noti: notification)
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: (() -> Void)) {
        let userInfo = response.notification.request.content.userInfo
        JPUSHService.handleRemoteNotification(userInfo)
        let notification = response.notification
        JPushMsgManager.backgroundPushPageJump(noti: notification)
    }
    
}
