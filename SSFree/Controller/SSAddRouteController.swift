//
//  SSAddRouteController.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/17.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit
import EasyTip

class SSAddRouteController: UIViewController {
    
    private lazy var defaultStand = UserDefaults.init(suiteName: "group.com.ssfree")!
    
    private lazy var navBar = UINavigationBar(frame: CGRect())
    private lazy var navItem = UINavigationItem(title: "添加线路")
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    /// 加密方式
    private var encryptionType: SSEncryptionTypeModel?
    /// 扫码获取的线路
    private var scanRoute: SSRouteModel?
    
    @IBOutlet weak var topBGViewHeightCons: NSLayoutConstraint!
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var encryptionTypeLabel: UILabel!
    
    class func addRoute(scanRoute: SSRouteModel?) -> SSAddRouteController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "AddRoute") as! SSAddRouteController
        vc.scanRoute = scanRoute
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_back"), style: .plain, target: self, action: #selector(back))
        navBar.items = [navItem]
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        view.addSubview(navBar)
        
        // 保存按钮
        let saveButton = UIButton()
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(UIColor.white, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        
        navItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        
        if let route = scanRoute {
            addressTF.text = route.ip_address
            portTF.text = "\(route.port)"
            passwordTF.text = route.password
            encryptionTypeLabel.text = route.encryptionType
            encryptionType = SSEncryptionTypeModel(name: route.encryptionType, isSelected: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let y = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        navBar.frame = CGRect(x: 0, y: y, width: UIScreen.main.bounds.width, height: 44)
        topBGViewHeightCons.constant = (UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20) + 44
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let traitCollection = previousTraitCollection else {
            return
        }
        
        switch traitCollection.userInterfaceStyle {
        case .dark:
            statusBarStyle = .lightContent
        default:
            statusBarStyle = .default
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    /// 返回
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    /// 保存
    @objc private func save() {
        guard let ip_address = addressTF.text,
            let port = portTF.text,
            let password = passwordTF.text,
            let encryption = encryptionType
            else {
                EasyTip.showStatusInfo(in: view, message: "信息不完整", complete: nil)
                return
        }
        
        let route = SSRouteModel(ip_address: ip_address, port: port, password: password, encryptionType: encryption.name!)
        
        let manager = FileManager.default
        guard let doc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let data = try? JSONEncoder().encode(route)
            else {
                EasyTip.error(in: view, message: "保存失败", complete: nil)
                return
        }
        let routeFilePath = "\(doc)/Routes.data"
        if manager.fileExists(atPath: routeFilePath) {
            guard let array = NSMutableArray(contentsOfFile: routeFilePath) else {
                EasyTip.error(in: view, message: "保存失败", complete: nil)
                return
            }
            array.add(data)
            if array.write(toFile: routeFilePath, atomically: true) {
                EasyTip.success(in: view, message: "保存成功") {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                EasyTip.error(in: view, message: "保存失败", complete: nil)
            }
        } else {
            if manager.createFile(atPath: routeFilePath, contents: nil, attributes: nil),
                NSArray(array: [data]).write(toFile: routeFilePath, atomically: true) {
                navigationController?.popViewController(animated: true)
                // 保存为默认路线
                defaultStand.set(data, forKey: "DefaultRoute")
                EasyTip.success(in: view, message: "保存成功", complete: nil)
            } else {
                EasyTip.error(in: view, message: "保存失败", complete: nil)
            }
        }
    }
    
    /// 选择加密方式
    @IBAction private func chooseEncryptionType() {
        view.endEditing(true)
        let vc = SSChooseEncryptionTypeController.chooseEncryptionType(currentType: encryptionType) { type in
            self.encryptionType = type
            self.encryptionTypeLabel.text = type.name
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
