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


extension DefaultsKeys {
    var rtkEnabled: DefaultsKey<Bool> { .init("rtkEnabled", defaultValue: false) }
    var rtkServerAddress: DefaultsKey<String?> { .init("rtkServerAddress") }
    var rtkPort: DefaultsKey<Int> { .init("rtkPort", defaultValue:  2101) }
    var rtkMountPoint: DefaultsKey<String?> { .init("rtkMountPoint") }
    var rtkUsername: DefaultsKey<String?> { .init("rtkUsername") }
    var rtkPassword: DefaultsKey<String?> { .init("rtkPassword") }
}
public struct RtkConfigurationRecord {
    let enabled: Bool
    let serverAddress: String?
    let port: Int?
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
    let configStatus = UILabel()
    
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
        configStatus.textColor = .white
        addStatus("Configuration Status", configStatus)
        
        let config = RtkManager.instance.config
        enabled.tintColor = .white
        enabled.isOn = config?.enabled ?? false
        addField("Enabled", enabled)
        serverAddress.tintColor = .white
        serverAddress.textColor = .white
        serverAddress.text = config?.serverAddress
        addField("Server Address", serverAddress)
        port.tintColor = .white
        port.textColor = .white
        port.keyboardType = .numberPad
        port.text = "\(config?.port ?? 2101)"
        addField("Port", port)
        mountPoint.tintColor = .white
        mountPoint.textColor = .white
        mountPoint.text = config?.mountPoint
        addField("Mount Point", mountPoint)
        userName.tintColor = .white
        userName.textColor = .white
        userName.text = config?.userName
        addField("Username", userName)
        password.tintColor = .white
        password.textColor = .white
        password.isSecureTextEntry = true
        password.text = config?.password
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
        configStatus.text = state.configurationStatus
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
                port: Int(port.text ?? "2021"),
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
    let configurationStatus: String
}
class RtkManager : NSObject {
    var config: RtkConfigurationRecord?
    let log = OSLog(subsystem: "DronelinkDJIUI", category: "RtkManager")
    
    public var logText = ""
    public static let instance = RtkManager()
    
    private var rtkState: DJIRTKState?
    private var networkState: DJIRTKNetworkServiceState?
    private var listners: [String: (_ update:RtkState) -> Void] = [:]
    private var lastState: RtkState = RtkState(state: nil, networkServiceState: nil, networkServiceStateText: "Unknown", positioningSolutionText: "Unknown", configurationStatus: "Unknown")
    private var aircraft: DJIAircraft?
    private var configurationState: String?
    
    public override init() {
        super.init()
        
        loadConfiguration()
    }
    public func loadConfiguration() {
        config = RtkConfigurationRecord(
            enabled: Defaults[\.rtkEnabled],
            serverAddress: Defaults[\.rtkServerAddress],
            port: Int(Defaults[\.rtkPort]),
            mountPoint: Defaults[\.rtkMountPoint],
            userName: Defaults[\.rtkUsername],
            password: Defaults[\.rtkPassword])
    }
    private func saveConfiguration() {
        guard self.config != nil else { return }
        
        let config = self.config!
        Defaults[\.rtkEnabled] = config.enabled
        Defaults[\.rtkServerAddress] = config.serverAddress
        Defaults[\.rtkPort] = config.port ?? 2101
        Defaults[\.rtkMountPoint] = config.mountPoint
        Defaults[\.rtkUsername] = config.userName
        Defaults[\.rtkPassword] = config.password
    }
    
    public func isRtkSupported() -> Bool {
        return self.aircraft?.flightController?.rtk != nil
    }
    private func connectToDrone(_ aircraft: DJIAircraft) {
        self.aircraft = aircraft
        if (aircraft.flightController?.delegate == nil){
            logText += "no del\n"
        }
        logText += "Drone Connect\n"
        DJISDKManager.rtkNetworkServiceProvider().addNetworkServiceStateListener("RtkManager", queue: nil) { (state: DJIRTKNetworkServiceState) in
            self.networkState = state
            self.update()
            if (state != nil) {
                self.logText += "Network update \(state.channelState)\n"
            }

        }
        if (aircraft.flightController?.rtk != nil) {
            let rtk = aircraft.flightController!.rtk!
            rtk.delegate = self
            logText += "FC RTK\n"
        }
        update()
        configure()
    }
    
    private func disconnectFromDrone() {
        self.aircraft = nil
        DJISDKManager.rtkNetworkServiceProvider().removeNetworkServiceStateListener("RtkManager")
    }
    
    public func addUpdateListner(key: String, closure: @escaping (_ update: RtkState) -> Void) {
        listners[key] = closure
        closure(lastState)
        //logText  += "Subscribe \(key)\n"
    }
    public func removeUpdateListner(key: String) {
        listners.removeValue(forKey: key)
        //logText  += "Unsubscribe \(key)\n"
    }
    
    private func update() {
        lastState = RtkState(
            state: rtkState,
            networkServiceState: networkState,
            networkServiceStateText: self.mapNetworkState(networkState?.channelState),
            positioningSolutionText: self.mapSolution(rtkState?.positioningSolution),
            configurationStatus: self.configurationState ?? "")
        
        logText  += "Update \(listners.count)\n"
        for (key, listner) in listners {
            listner(lastState)
        }
    }
    
    func configure() {
        guard self.aircraft?.flightController?.rtk != nil else {
            os_log(.default, log: self.log, "RTK not available on flightcontroller")
            logText += "conf no rtk\n"
            self.configurationState = "RTK not supported"
            return
        }
            
        let rtk = self.aircraft!.flightController!.rtk!
        
        if config == nil || config?.enabled == false {
            rtk.setEnabled(false, withCompletion: { (error: Error?) in
                self.configurationState = "RTK disable failed: \(error?.localizedDescription)"
                self.logText += "RTK disable failed: \(error?.localizedDescription)\n"
            })
            self.configurationState = "RTK disabled"
            update()
            return
        }
        
        let config = self.config!
        guard (config.serverAddress?.count ?? 0 >= 0) else {
            self.configurationState = "Configuration incomplete"
            return
        }
        
        ConfigureRtkHelper.configureRtk(aircraft: aircraft!, config: config) { (error: Error?, msg: String) in
            self.logText += msg + "\n"
            self.configurationState = msg
        } withSuccess: {
            self.logText += "RTK OK"
            self.configurationState = "OK"
        }
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
extension RtkManager : RtkConfigurationUpdated {
    func onConfigurationUpdate(config: RtkConfigurationRecord) {
        self.config = config
        
        saveConfiguration()
        
        configure()
    }
}

extension RtkManager : DJIRTKDelegate {
    func didUpdateState(state: DJIRTKState) {
        self.rtkState = state
        logText += "Rtk update \(state)\n"
        self.update()
    }
}
extension RtkManager :DroneSessionManagerDelegate {
    
    func onOpened(session: DronelinkCore.DroneSession) {
        if let drone = session.drone as? DJIDroneAdapter {
            self.connectToDrone(drone.drone)
        }
    }

    func onClosed(session: DronelinkCore.DroneSession){
        self.disconnectFromDrone()
    }
}

class ConfigureRtkHelper {
    public static func configureRtk(
        aircraft: DJIAircraft,
        config: RtkConfigurationRecord,
        withError: @escaping (_ error: Error?, _ action: String) -> Void,
        withSuccess: @escaping () -> Void
    ) {
        guard aircraft.flightController?.rtk != nil else { return }
        
        ConfigureRtkHelper(aircraft.flightController!.rtk!, config, withError, withSuccess).stopNetwork()
    }
    
    let log = OSLog(subsystem: "DronelinkDJIUI", category: "ConfigureRtkHelper")
    let rtk: DJIRTK
    let config: RtkConfigurationRecord
    let withError: (_ error: Error?, _ action: String) -> Void
    let withSuccess: () -> Void

    
    private init(_ rtk: DJIRTK, _ config: RtkConfigurationRecord, _ withError: @escaping (_ error: Error?, _ action: String) -> Void, _ withSuccess: @escaping () -> Void) {
        
        self.rtk = rtk
        self.config = config
        self.withError = withError
        self.withSuccess = withSuccess
        
        stopNetwork()
    }
    private func stopNetwork() {
        DJISDKManager.rtkNetworkServiceProvider().stopNetworkService() { (error: Error?) in
            if self.noError(error: error, action: "Stop RTK Network Service") {
                self.enableRtk()
            }
        }
    }
    private func enableRtk() {
        rtk.setEnabled(true) { (error: Error?) in
            if self.noError(error: error, action: "Enable RTK") {
                self.setSettings()
            }
        }
    }
    private func setSettings() {
        var settings = DJIMutableRTKNetworkServiceSettings()
        settings.mountpoint = config.mountPoint
        settings.password = config.password
        settings.port = Int32(config.port!)
        settings.serverAddress = config.serverAddress
        settings.userName = config.userName
        
        DJISDKManager.rtkNetworkServiceProvider().setNetworkServiceSettings(settings)
        
        setReferenceStation()
    }
    private func setReferenceStation() {
        rtk.setReferenceStationSource(.customNetworkService) { (error: Error?) in
            if self.noError(error: error, action: "Set reference station custom") {
                self.startNetwork()
            }
        }
    }
    private func startNetwork() {
        DJISDKManager.rtkNetworkServiceProvider().startNetworkService { (error: Error?) in
            if self.noError(error: error, action: "Start network") {
                self.withSuccess()
            }
        }
    }
    
    private func noError(error: Error?, action: String) -> Bool {
        if error != nil {
            let msg: String = error?.localizedDescription ?? "Unknown"
            self.withError(error, "Failed to \(action): \(msg)\n")
            os_log(.error, log: self.log, "Failed to %@: %@", action, msg)
            return false
        }
        return true
    }
}
