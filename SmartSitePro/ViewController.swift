//
//  ViewController.swift
//  SmartSitePro
//
//  Created by lijian on 2024/1/21.
//

import UIKit
import WebKit
import SnapKit

class ViewController: UIViewController {
    
    var getRidTimes: Int = 1
    
    let rootUrl: String = "http://hjkjgd.sinochemehc.com/app/#/login"
    let updateLatestVersionFunc = "iOSUpdateApp"
    let jsJumpPageByJPushFunc = "onPushJG"
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("进入了")
        view.backgroundColor = UIColor.white
        clearCacheWKWebview()
        setupUI()
        addObserverForWebView()
        loadH5Url()
        addObserverNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addJSMessageHandler()
    }
    
    func setupUI() {
        view.addSubview(bgImageView)
        view.addSubview(webView)
        view.addSubview(progressView)
        bgImageView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        webView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.bottom.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
    }

    func loadH5Url() {
        let realUrl = URL(string: rootUrl)
        let request = URLRequest.init(url: realUrl ?? URL(fileURLWithPath: ""))
        webView.load(request)
    }
    
    lazy var bgImageView: UIImageView = {
        let i = UIImageView.init()
        i.image = UIImage(named: "mmexport1663141553196")
        return i
    }()
    
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
//        config.applicationNameForUserAgent = YXTools.getAppUserAgentInfo()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypes.all
        config.userContentController = userContent
        let web = WKWebView.init(frame: CGRect.zero, configuration: config)
        web.allowsBackForwardNavigationGestures = true
        web.navigationDelegate = self
//        web.uiDelegate = self
        web.scrollView.delegate = self
        return web
    }()
    
    lazy var progressView: UIProgressView = {
        let pw = UIProgressView()
        pw.trackTintColor = .white
        pw.progressTintColor = .blue
        return pw
    }()
    
    lazy var userContent: WKUserContentController = {
        let js = " $('meta[name=description]').remove(); $('head').append( '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1,user-scalable=no\">' );"
        let script = WKUserScript.init(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        let con = WKUserContentController.init()
        con.addUserScript(script)
        return con
    }()
    
    func addJSMessageHandler() {
        webView.configuration.userContentController.add(self, name: updateLatestVersionFunc)
    }
    
    func removeJSMessageHandler() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: updateLatestVersionFunc)
    }
    
    /**
     清除缓存
     */
    func clearCacheWKWebview() {
        let types = [WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeDiskCache]
        let websiteDataTypes = Set.init(types)
        let dateFrom = Date.init(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
            
        }
    }
    
    func setCurrentVersion() {
        let localStorageString = "localStorage.setItem('updateVersion', '\(latestVersion)')"
        webView.evaluateJavaScript(localStorageString)
    }
    
    @objc func getVersion() {
        let localStorageString = "localStorage.getItem('updateVersion')"
        webView.evaluateJavaScript(localStorageString) { result, error in
            
        }
    }
    
    func setRid() {
        if getRidTimes < 11 {
            JPUSHService.registrationIDCompletionHandler { code, rid in
                print("获取的极光resCode = \(code)---- rid = \(String(describing: rid))")
                if rid?.isBlank ?? true {
                    self.getRidTimes += 1
                    self.setRid()
                } else {
                    let localStorageString = "localStorage.setItem('rid', '\(rid?.description ?? "")')"
                    self.webView.evaluateJavaScript(localStorageString)
                }
            }
        }
    }
}

// MARK: 容器代理事件
extension ViewController: WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollViewDidScroll - \(scrollView.contentOffset.y)")
        if scrollView.contentOffset.y < 0 {
            var offset = scrollView.contentOffset
            offset.y = 0
            scrollView.contentOffset = offset
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("开始")
    }
    
    // 监听链接变化
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("链接变化 -- \(String(describing: webView.url ?? URL(string: "")))")
        decisionHandler(.allow)
        
//        if(navigationAction.navigationType == .reload) {
//                  decisionHandler(.cancel)
//                  return
//              }
//              decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("加载完成 \n 链接：\(String(describing: webView.url))")
        progressView.setProgress(0.0, animated: false)
        setCurrentVersion()
        setRid()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("加载失败") //reportFile is close
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("加载错误")
    }
    
    // 监听按钮点击事件
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("js 消息 \(message.name) --- \(message.body)")
        
        // 跳转到app store 去升级最新的APP
        if message.name == updateLatestVersionFunc {
            goAppStore()
        }
        
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        
        completionHandler(.useCredential, cred)
        
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("内存过高进入啦i")
    }

    //didReceiveAuthenticationChallenge
}

// MARK: 容器UI代理
extension ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
    }
}

extension ViewController {
    
    func sendParamsToJS(javaScriptString: String, completion: ((_ resultStatus: Bool?) -> Void)?) {
        if javaScriptString.isBlank {
            print("js 方法不能为空")
            return
        }
        webView.evaluateJavaScript(javaScriptString) { obj, error in
            print("掉用JS方法的回调 -- \(String(describing: error))")
            guard let complete = completion else { return }
            if error != nil {
                complete(false)
            } else {
                complete(true)
            }
        }
        
    }
    
    private func goAppStore() {
        guard let url = URL(string: myAppStoreUrl) else { return }
        let can = UIApplication.shared.canOpenURL(url)
        if can {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { (b) in
                    print("打开结果: \(b)")
                }
            } else {
                //iOS 10 以前
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func addObserverForWebView() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress >= 1 ? true : false
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        commonBack()
        return false
    }
}

extension String {
    /// 通过高阶函数allSatisfy，判断字符串是否为空串
    var isBlank:Bool{
        /// 字符串中的所有字符都符合block中的条件，则返回true
        let _blank = self.allSatisfy{
            let _blank = $0.isWhitespace
//            print("字符：\($0) \(_blank)")
            return _blank
        }
        return _blank
    }
}


extension ViewController {

    func addObserverNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(popMsgAlert(noti: )), name: NSNotification.Name.init(rawValue: jiGuang_alert_notification_name), object: nil)
    }
    
    @objc func popMsgAlert(noti: Notification) {
        
        let notiMsgBody = noti.object as? [String: Any]
        let msgAps: [String: Any] = notiMsgBody?["aps"] as? [String: Any] ?? [:]
        let msgAlert: [String: Any] = msgAps["alert"] as? [String: Any] ?? [:]
        let msgTitle: String = msgAlert["title"] as? String ?? "提示"
        let msgBody: String = msgAlert["body"] as? String ?? "有新的任务需要处理"
        
        let msgUrl: String = notiMsgBody?["url"] as? String ?? ""
        
        let alert = UIAlertController.init(title: msgTitle, message: msgBody, preferredStyle: .alert)
        let sure = UIAlertAction.init(title: "查看", style: .default) { a in
            if msgUrl.isBlank {
                EWToast.showCenterWithText(text: "跳转配置异常", duration: CGFloat(toastDispalyDuration))
            } else {
                let paramDic: [String: Any] = ["url": msgUrl]
                let data: Data! = try? JSONSerialization.data(withJSONObject: paramDic, options: []) as Data
                let JSONString = String(data: data as Data, encoding: .utf8)!
                let javaScriptString = "\(self.jsJumpPageByJPushFunc)('\(JSONString)');"
                self.sendParamsToJS(javaScriptString: javaScriptString, completion: nil)
            }
        }
        let cancel = UIAlertAction.init(title: "取消", style: .cancel) { a in }
        alert.addAction(sure)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

}
