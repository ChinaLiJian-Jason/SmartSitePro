//
//  JPushMsgManager.swift
//  SmartSitePro
//
//  Created by lijian on 2024/2/18.
//

import Foundation
import UIKit

class JPushMsgManager {
    
    static func foregroundPushPageJump(noti: UNNotification) {
        let userInfo = noti.request.content.userInfo as? [String: Any]
        receiveMsgBody(msgBody: userInfo ?? [:])
    }

    static func backgroundPushPageJump(noti: UNNotification) {
        let userInfo = noti.request.content.userInfo as? [String: Any]
        receiveMsgBody(msgBody: userInfo ?? [:], isForeground: true)
    }
    
    private static func receiveMsgBody(msgBody: [String: Any], isForeground: Bool = false) {
        if msgBody.keys.count == 0 { return }
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: jiGuang_alert_notification_name), object: msgBody)
    }
    

}
