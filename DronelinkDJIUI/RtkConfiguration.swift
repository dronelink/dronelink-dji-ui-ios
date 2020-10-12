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
import MaterialComponents.MaterialButtons
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
    let headingConfiguration = UILabel()
    let headingStatus = UILabel()
    var statusControls: [(label: UILabel, control: UIView)] = []
    var controls: [(label: UILabel, control: UIView)] = []
    let serverAddress = MDCTextField()
    let port = MDCTextField()
    let mountPoint = MDCTextField()
    let userName = MDCTextField()
    let password = MDCTextField()
    let confirm = MDCButton()
    let enabled = UISwitch()
    let scroll = UIScrollView()
    let networkStatus = UILabel()
    let rtkSolution = UILabel()
    
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
        
        scroll.backgroundColor = .black
        scroll.contentSize = view.frame.size
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        
        headingStatus.text = "RTK Status"
        headingStatus.textColor = .white
        scroll.addSubview(headingStatus)
        
        headingConfiguration.text = "RTK Network Configuration"
        headingConfiguration.textColor = .white
        scroll.addSubview(headingConfiguration)
        
        closeButton.setTitle("x", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(onClose),for: .touchUpInside)
        view.addSubview(closeButton)
        
        networkStatus.textColor = .white
        addStatus("Network Service", networkStatus)
        rtkSolution.textColor = .white
        addStatus("RTK Solution", rtkSolution)
        
        enabled.tintColor = .white
        addField("Enabled", enabled)
        serverAddress.tintColor = .white
        serverAddress.textColor = .white
        serverAddress.text = RtkManager.instance.logText.replacingOccurrences(of: "\n", with: ";")
        addField("Server Address", serverAddress)
        port.tintColor = .white
        port.textColor = .white
        port.keyboardType = .numberPad
        addField("Port", port)
        mountPoint.tintColor = .white
        mountPoint.textColor = .white
        addField("Mount Point", mountPoint)
        userName.tintColor = .white
        userName.textColor = .white
        addField("Username", userName)
        password.tintColor = .white
        password.textColor = .white
        addField("Password", password)
        
        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = UIColor.darkGray
        confirm.applyContainedTheme(withScheme: scheme)
        confirm.setTitle("Confirm", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.addTarget(self, action: #selector(onConfirm),for: .touchUpInside)
        scroll.addSubview(confirm)
          
        RtkManager.instance.addUpdateListner(key: "RtkConfiguration", closure: { (state: RtkState) in
            self.statusUpdate(state)
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        RtkManager.instance.removeUpdateListner(key: "RtkConfiguration")
    }
    private func statusUpdate(_ state: RtkState) {
        networkStatus.text = state.networkServiceStateText
        rtkSolution.text = state.positioningSolutionText
    }
    private func addField(_ title: String, _ control: UIView) {
        let label = UILabel()
        label.text = title
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        scroll.addSubview(label)

        scroll.addSubview(control)

        controls.append((label: label, control: control))
    }
    private func addStatus(_ title: String, _ control: UILabel) {
        let label = UILabel()
        label.text = title
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.adjustsFontSizeToFitWidth = true
        scroll.addSubview(label)

        control.textColor = .white
        control.font = UIFont.systemFont(ofSize: 12)
        scroll.addSubview(control)

        statusControls.append((label: label, control: control))
    }
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let padding = 8
        scroll.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        closeButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-padding)
            make.top.equalToSuperview().offset(padding)
        }
        view.bringSubviewToFront(closeButton)
        
        headingStatus.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(padding)
            make.left.equalTo(view.snp.left).offset(padding)
        }
        
        var previous: UIView = headingStatus
        for (label, control) in self.statusControls {
            control.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(100 + padding)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-padding)
                make.height.equalTo(15)
            }
            
            label.snp.remakeConstraints { make in
                make.top.equalTo(control.snp.top)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(padding)
                make.width.equalTo(100)
            }
            
            previous = control
        }
        
        headingConfiguration.snp.remakeConstraints { make in
            make.top.equalTo(previous.snp.bottom).offset(padding + 8)
            make.left.equalTo(view.snp.left).offset(padding)
        }
        previous = headingConfiguration
        for (label, control) in self.controls {
            control.snp.remakeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(100 + padding)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-padding)
            }
            
            label.snp.remakeConstraints { make in
                make.bottom.equalTo(control.snp.bottom).offset(-8)
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
        //dismiss(animated: true, completion: nil)
    }
}
struct RtkState {
    let state: DJIRTKState?
    let networkServiceState: DJIRTKNetworkServiceState?
    let networkServiceStateText: String
    let positioningSolutionText: String
}
class RtkManager : NSObject, RtkConfigurationUpdated {
    var config: RtkConfigurationRecord?
    let log = OSLog(subsystem: "DronelinkDJIUI", category: "RtkManager")
    
    func onConfigurationUpdate(config: RtkConfigurationRecord) {
        self.config = config
        // Store somewhere
        configure()
        
    }
   public var logText = ""
    public static let instance = RtkManager()
    private override init() {
        super.init()
        
        DJISDKManager.startListeningOnProductConnectionUpdates(withListener: (Any).self) { (product: DJIBaseProduct?) in
            if let aircraft = product as? DJIAircraft {
                if (aircraft.flightController?.rtk != nil) {
                    aircraft.flightController?.rtk?.delegate = self
                }
                self.configure(aircraft)
                self.logText += "Aircraft connected\n"
            }
            else {
                self.lastState = RtkState(state: nil, networkServiceState: nil, networkServiceStateText: "Disconnected", positioningSolutionText: "Disconnected")
                self.update()
                self.logText += "Aircraft not connected\n"
            }
        }
        DJISDKManager.rtkNetworkServiceProvider().addNetworkServiceStateListener("RtkManager", queue: nil) { (state: DJIRTKNetworkServiceState) in
            self.networkState = state
            self.update()
            if (state != nil) {
                self.logText += "Network update \(state.channelState)\n"
            }

        }
        configure()
    }
    private var rtkState: DJIRTKState?
    private var networkState: DJIRTKNetworkServiceState?
    private var listners: [String: (_ update:RtkState) -> Void] = [:]
    private var lastState: RtkState = RtkState(state: nil, networkServiceState: nil, networkServiceStateText: "Unknown", positioningSolutionText: "Unknown")
    
    public func addUpdateListner(key: String, closure: @escaping (_ update: RtkState) -> Void) {
        listners[key] = closure
        closure(lastState)
        logText  += "Subscribe \(key)\n"
    }
    public func removeUpdateListner(key: String) {
        listners.removeValue(forKey: key)
        logText  += "Unsubscribe \(key)\n"
    }
    private func update() {
        lastState = RtkState(
            state: rtkState,
            networkServiceState: networkState,
            networkServiceStateText: self.mapNetworkState(networkState?.channelState),
            positioningSolutionText: self.mapSolution(rtkState?.positioningSolution))
        
        logText  += "Update \(listners.count)\n"
        for (key, listner) in listners {
            listner(lastState)
        }
    }
    func configure() {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            self.configure(aircraft)
        }
    }
    func configure(_ aircraft: DJIAircraft? ) {
        if aircraft?.flightController?.rtk == nil {
            return
        }
            
        let rtk = aircraft!.flightController!.rtk!
        
        if config == nil || config?.enabled == false {
            rtk.setEnabled(false, withCompletion: { (error: Error?) in
                self.noError(error: error, action: "Disable RTK")
            })
            return
        }
        
        let config = self.config!
        rtk.setEnabled(true) { (error: Error?) in
            if self.noError(error: error, action: "Enable RTK") {
                self.stopNetwork()
            }
        }
    }
    private func stopNetwork() {
        let networkProvider = DJISDKManager.rtkNetworkServiceProvider()
        networkProvider.stopNetworkService { (error: Error?) in
            if self.noError(error: error, action: "Stop RTK Network Service") {
                self.setSettings()
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
        Dronelink.shared.announce(message: "Completed RTK")
    }
    private func noError(error: Error?, action: String) -> Bool {
        if error != nil {
            let msg: String = error?.localizedDescription ?? "Unknown"
            Dronelink.shared.announce(message: "Failed to \(action): \(msg)")
            os_log(.error, log: self.log, "Failed to %@: %@", action, msg)
            return false
        }
        return true
    }
    
    
    private func mapSolution(_ solution: DJIRTKPositioningSolution?) -> String {
        switch (solution) {
        case .fixedPoint:
            return "Fixed"
        case .float:
            return "Float"
        case .none:
            return "None"
        case .singlePoint:
            return "Single"
        default:
            return "Unknown"
        }
    }
    private func mapNetworkState(_ state: DJIRTKNetworkServiceChannelState?) -> String
    {
        switch (state) {
        case .accountError:
            return "Account error"
        case .aircraftDisconnected:
            return "Aircraft disconnected"
        case .connecting:
            return "Connecting"
        case .disabled:
            return "Disabled"
        case .disconnected:
            return "Disconnected"
        case .invalidRequest:
            return "Invalid request"
        case .loginFailure:
            return "Login failure"
        case .networkNotReachable:
            return "Network not reachable"
        case .ready:
            return "Ready"
        case .serverNotReachable:
            return "Server not reachablke"
        case .serviceSuspension:
            return "Service suspension"
        case .transmitting:
            return "Transmitting"
        default:
            return "Unknown"
        }
    }
}
extension RtkManager : DJIRTKDelegate {
    func didUpdateState(state: DJIRTKState) {
        self.rtkState = state
        logText += "Rtk update \(state)\n"
        self.update()
    }
}

