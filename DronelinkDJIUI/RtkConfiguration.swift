//
//  RtkConfiguration.swift
//  DronelinkDJIUI
//
//  Created by Patrick Verbeeten on 11/10/2020.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import os
import Foundation
import UIKit
import SnapKit
import JavaScriptCore
import DronelinkCore
import DronelinkCoreUI
import DronelinkDJI
import DJIUXSDK
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialTextFields
import Kingfisher
import SwiftyUserDefaults

public struct RtkConfigurationRecord {
    let enabled: Bool
    let serverAddress: String?
    let port: Int32?
    let mountPoint: String?
    let userName: String?
    let password: String?
}
public protocol RtkConfigurationUpdated {
    func onConfigurationUpdate(config: RtkConfigurationRecord)
}
class RtkConfiguration : UIViewController {
    let closeButton = UIButton()
    let heading = UILabel()
    var controls: [(label: UILabel, control: UIView)] = []
    let serverAddress = MDCTextField()
    let port = MDCTextField()
    let mountPoint = MDCTextField()
    let userName = MDCTextField()
    let password = MDCTextField()
    let confirm = UIButton()
    let enabled = UISwitch()
    
    public var delegate: RtkConfigurationUpdated?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        self.preferredContentSize = CGSize(width: 400, height: 460)
        view.addShadow()
        
        view.backgroundColor = .black
        
        heading.text = "RTK Network Configuration"
        heading.textColor = .white
        view.addSubview(heading)
        
        closeButton.setTitle("x", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(onClose),for: .touchUpInside)
        view.addSubview(closeButton)
        
        enabled.tintColor = .white
        addField(title: "Enabled", control: enabled)
        serverAddress.tintColor = .white
        serverAddress.textColor = .white
        addField(title: "Server Address", control: serverAddress)
        port.tintColor = .white
        port.textColor = .white
        addField(title: "Port", control: port)
        mountPoint.tintColor = .white
        mountPoint.textColor = .white
        addField(title: "Mount Point", control: mountPoint)
        userName.tintColor = .white
        userName.textColor = .white
        addField(title: "Username", control: userName)
        password.tintColor = .white
        password.textColor = .white
        addField(title: "Password", control: password)
        
        confirm.setTitle("Confirm", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.addTarget(self, action: #selector(onConfirm),for: .touchUpInside)
        view.addSubview(confirm)
    }
    private func addField(title: String, control: UIView) {
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        view.addSubview(label)

        view.addSubview(control)

        controls.append((label: label, control: control))
    }
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let padding = 8

        closeButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-padding)
            make.top.equalTo(view.snp.top).offset(padding)
        }
        heading.snp.remakeConstraints { make in
            make.top.equalTo(view.snp.top).offset(padding)
            make.left.equalTo(view.snp.left).offset(padding)
            make.width.equalTo(300)
        }
        
        var previous: UIView = heading
        for (label, control) in self.controls {
            control.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(padding)
                make.left.equalTo(label.snp.right)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-padding)
            }
            
            label.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(padding + 2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(padding)
                make.width.equalTo(100)
            }
            
            previous = control
        }
        
        confirm.snp.remakeConstraints { make in
            make.top.equalTo(previous.snp.bottom).offset(padding)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-padding)
        }
    }
    
    @objc func onClose(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }
    @objc func onConfirm(sender: UIButton!) {
        if delegate != nil {
            delegate?.onConfigurationUpdate(config: RtkConfigurationRecord(
                enabled: enabled.isOn,
                serverAddress: serverAddress.text,
                port: Int32(port.text ?? "2021"),
                mountPoint: mountPoint.text,
                userName: userName.text,
                password: password.text
            ))
        }
    }
}

class RtkManager : RtkConfigurationUpdated {
    var config: RtkConfigurationRecord?
    let log = OSLog(subsystem: "DronelinkDJIUI", category: "RtkManager")
    
    func onConfigurationUpdate(config: RtkConfigurationRecord) {
        self.config = config
        // Store somewhere
    }
    
    func configure(aircraft: DJIAircraft ) {
        if aircraft.flightController?.rtk == nil {
            return
        }
            
        let rtk = aircraft.flightController!.rtk!
        
        if config == nil || config?.enabled == false {
            rtk.setEnabled(false, withCompletion: { (error: Error?) in
                self.noError(error: error, action: "Disable RTK")
            })
            return
        }
        
        let config = self.config!
        rtk.setEnabled(true) { (error: Error?) in
            if self.noError(error: error, action: "Enable RTK") {
                
            }
        }
    }
    private func stopNetwork() {
        let networkProvider = DJISDKManager.rtkNetworkServiceProvider()
        networkProvider.stopNetworkService { (error: Error?) in
            if self.noError(error: error, action: "Stop RTK Network Service") {
                
            }
        }
    }
    private func setSettings() {
        let config = self.config!
        
        let networkProvider = DJISDKManager.rtkNetworkServiceProvider()
        var settings = DJIMutableRTKNetworkServiceSettings()
        settings.mountpoint = config.mountPoint
        settings.password = config.password
        settings.port = config.port!
        settings.serverAddress = config.serverAddress
        settings.userName = config.userName
        
        networkProvider.setNetworkServiceSettings(settings)
    }
    private func noError(error: Error?, action: String) -> Bool {
        if error != nil {
            let msg: String = error?.localizedDescription ?? "Unknown"
            os_log(.error, log: self.log, "Failed to %@: %@", action, msg)
            return false
        }
        return true
    }
}
