//
//  DJIRTKManager.swift
//  DronelinkDJI
//
//  Created by Patrick Verbeeten on 19/10/2020.
//

import os
import Foundation
import DJISDK
import SwiftyUserDefaults
import DronelinkCore

extension DefaultsKeys {
    var rtkAutoConnect: DefaultsKey<Bool> { .init("rtkAutoConnect", defaultValue: false) }
    var rtkServerAddress: DefaultsKey<String?> { .init("rtkServerAddress") }
    var rtkPort: DefaultsKey<Int> { .init("rtkPort", defaultValue:  2101) }
    var rtkMountPoint: DefaultsKey<String?> { .init("rtkMountPoint") }
    var rtkUsername: DefaultsKey<String?> { .init("rtkUsername") }
    var rtkPassword: DefaultsKey<String?> { .init("rtkPassword") }
}

public struct RTKConfigurationRecord {
    var enabled: Bool
    let autoConnect: Bool
    let serverAddress: String?
    let port: Int?
    let mountPoint: String?
    let userName: String?
    let password: String?
}

public enum NetworkRTKStatus {
    case notSupported
    case disabled
    case connecting
    case connected
    case error
    case timeout
}
public struct RTKState {
    let networkRTKEnabled: Bool
    let networkRTKConnected: Bool
    let networkRTKStatus: NetworkRTKStatus
    let networkServiceStateText: String
    let configurationStatus: String
}

public class DJIRTKManager : NSObject {
    private var config: RTKConfigurationRecord!
    private let log = OSLog(subsystem: "DronelinkDJIUI", category: "DJIRTKManager")
    
    private var networkState: DJIRTKNetworkServiceState?
    private var listners: [String: (_ update:RTKState) -> Void] = [:]
    private var lastState: RTKState = RTKState(networkRTKEnabled: false, networkRTKConnected: false, networkRTKStatus: .notSupported, networkServiceStateText: "RTK.channelstate.unknown".localized, configurationStatus: "RTK.configstate.unknown".localized)
    private var aircraft: DJIAircraft!
    private var configurationState: String?
    private var configuring: Bool = false
    private var waitForConnection: Bool = false
    private var timeout: Bool = false
    private var initialized: Bool = false
    private var initializationAttempt: Int = 0
    private var managerIsConnected: Bool = false
    
    public init(_ drone: DJIAircraft!) {
        super.init()
        self.aircraft = drone
        
        initRTK()
    }
    
    private func initRTK() {
        guard aircraft.flightController?.rtk != nil else {
            // In this state the RTK manager is not fully configured and will not detect RTK state changes
            // flightController.rtk may be initialized a little later so a few rechecks are scheduled

            if (initializationAttempt < 5) {
                os_log(.debug, log: self.log, "Initialize; Flightcontroller.RTK not set, scheduling recheck (%d)", initializationAttempt)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.initializationAttempt += 1
                    self.initRTK()
                }
            }
            else {
                os_log(.info, log: self.log, "Initialize; RTK not supported")
            }
            return
        }
        
        //Initialization should only happen once
        if (initialized) {
            os_log(.debug, log: self.log, "Initialize; RTK already initialized")
            self.update()
            return
        }
        
        config = RTKConfigurationRecord(
            enabled: false,
            autoConnect: Defaults[\.rtkAutoConnect],
            serverAddress: Defaults[\.rtkServerAddress],
            port: Int(Defaults[\.rtkPort]),
            mountPoint: Defaults[\.rtkMountPoint],
            userName: Defaults[\.rtkUsername],
            password: Defaults[\.rtkPassword])
        
        os_log(.info, log: log, "Initialize; RTK supported: %@; AutoConnect: %@", self.isRtkSupported() ? "yes" : "no", config.autoConnect ? "Yes" : "No")
        
        DJISDKManager.rtkNetworkServiceProvider().addNetworkServiceStateListener("DJIRTKManager", queue: nil) { (state: DJIRTKNetworkServiceState) in
            if self.networkState != state {
                os_log(.info, log: self.log, "Network state listner: %@, connecting: %@", self.mapNetworkState(state.channelState), self.waitForConnection ? "waiting" : "no")
            }
            
            self.networkState = state
            
            if self.waitForConnection {
                if state.channelState != .connecting {
                    self.waitForConnection = false
                }
            }
            self.update()
        }
        initialized = true
        timeout = false
        
        self.update()
        let rtk = aircraft.flightController!.rtk!
        
        rtk.getEnabledWithCompletion({ (enabled: Bool, error: Error?) in
            if (error == nil) {
                self.config.enabled = enabled

                os_log(.debug, log: self.log, "RTK init enabled check: %@", enabled ? "yes" : "no")
                
                if self.config.autoConnect && (!enabled || !self.managerIsConnected) {
                    self.config.enabled = true
                    os_log(.info, log: self.log, "Starting auto connect")
                    self.configure()
                }
            }
            else {
                os_log(.error, log: self.log, "Error get RTK enabled: %{public}s", error!.localizedDescription)
            }
        })
    }
    public func close() {
        DJISDKManager.rtkNetworkServiceProvider().removeNetworkServiceStateListener("DJIRTKManager")
        self.aircraft = nil
        listners.removeAll()
    }
    
    public func getConfiguration() -> RTKConfigurationRecord! {
        return config
    }
    public func setConfiguration(_ config: RTKConfigurationRecord) {
        self.config = config
        configure()
        saveConfiguration()
    }
    private func saveConfiguration() {
        guard self.config != nil else { return }
        
        let config = self.config!
        Defaults[\.rtkAutoConnect] = config.autoConnect
        Defaults[\.rtkServerAddress] = config.serverAddress
        Defaults[\.rtkPort] = config.port ?? 2101
        Defaults[\.rtkMountPoint] = config.mountPoint
        Defaults[\.rtkUsername] = config.userName
        Defaults[\.rtkPassword] = config.password
    }
    
    public func isRtkSupported() -> Bool {
        return self.aircraft?.flightController?.rtk != nil
    }

    public func addUpdateListner(key: String, closure: @escaping (_ update: RTKState) -> Void) {
        listners[key] = closure
        closure(lastState)
    }
    public func removeUpdateListner(key: String) {
        listners.removeValue(forKey: key)
    }
    
    public func getNetworkRTKStatus() -> NetworkRTKStatus {
        if aircraft?.flightController?.rtk == nil {
            return .notSupported
        }
        else if config == nil || !config!.enabled {
            return .disabled
        }
        else if configuring || waitForConnection {
            if !configuring && timeout {
                return .timeout
            }
            
            // There is a delay between finishing the RTK configuration and network RTK actually connecting,
            // waitForConnection tracks this and keeps the status in connecting.
            return .connecting
        }
        else if networkState != nil {
            if networkState!.channelState == .connecting {
                return .connecting
            }
            else if networkState!.channelState == .transmitting {
                return .connected
            }
            else {
                return .error
            }
        }
        
        return .error
    }
    
    private func update() {
        let status = self.getNetworkRTKStatus()
        
        lastState = RTKState(
            networkRTKEnabled: config?.enabled ?? false,
            networkRTKConnected: networkState?.channelState == .transmitting,
            networkRTKStatus: status,
            networkServiceStateText: status == .disabled
                ? "RTK.channelstate.disabled".localized
                : self.mapNetworkState(networkState?.channelState),
            configurationStatus: self.configurationState ?? "RTK.configstate.loaded".localized)
        
        
        for (_, listner) in self.listners {
            listner(self.lastState)
        }
    }
    
    func configure() {
        guard self.aircraft?.flightController?.rtk != nil else {
            os_log(.default, log: self.log, "RTK not available on flightcontroller")
            
            self.configurationState = "RTK.configstate.notsupported".localized
            return
        }
        
        let rtk = self.aircraft!.flightController!.rtk!
        timeout = false
        
        if config == nil || config?.enabled == false {
            
            if(managerIsConnected) {
                // Attempt to stop the network service if it was previously started.
                DJISDKManager.rtkNetworkServiceProvider().stopNetworkService()
            }
            managerIsConnected = false
            
            rtk.setEnabled(false, withCompletion: { (error: Error?) in
                if (error == nil) {
                    self.configurationState = "RTK.configstate.disabled".localized
                }
                else {
                    self.configurationState = "\("RTK.configstate.disablefailed".localized): \(String(describing: error?.localizedDescription))"
                }
                self.configuring = false
                self.update()
            })
            
            return
        }
        let config = self.config!
        guard (config.serverAddress?.count ?? 0 >= 0) else {
            self.managerIsConnected = false
            self.configurationState = "RTK.configstate.incomplete".localized
            self.update()
            return
        }
        
        if (self.configuring) {
            return
        }
        self.configuring = true
        
        self.managerIsConnected = true
        self.configurationState = "Configuring"
        self.update()
        
        ConfigureRtkHelper.configureRtk(aircraft: aircraft!, config: config) { (error: Error?, msg: String) in
            self.configuring = false
            self.configurationState = msg
            self.update()
            self.managerIsConnected = false
        } withSuccess: {
            self.configuring = false
            self.waitForConnection = true
            self.configurationState = "RTK.configstate.ok".localized
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if self.waitForConnection {
                    self.timeout = true
                    self.update()
                }
            }
            self.update()
            
        }
    }
    
    private func mapNetworkState(_ state: DJIRTKNetworkServiceChannelState?) -> String
    {
        if (state == nil) {
            if (self.configuring) {
                return "RTK.configstate.configuring".localized
            }
            else if (self.config.enabled) {
                return "RTK.configstate.enabled".localized
            }
            else {
                return "RTK.configstate.disabled".localized
            }
        }
        
        switch (state) {
        case .accountError:
            return "RTK.channelstate.accounterror".localized
        case .aircraftDisconnected:
            return "RTK.channelstate.airecraftdisconnected".localized
        case .connecting:
            return "RTK.channelstate.connecting".localized
        case .disabled:
            return "RTK.channelstate.disabled".localized
        case .disconnected:
            return "RTK.channelstate.disconnected".localized
        case .invalidRequest:
            return "RTK.channelstate.invalidrequest".localized
        case .loginFailure:
            return "RTK.channelstate.loginfailure" .localized
        case .networkNotReachable:
            return "RTK.channelstate.networknotreachable".localized
        case .ready:
            return "RTK.channelstate.ready".localized
        case .serverNotReachable:
            return "RTK.channelstate.servernotreachable".localized
        case .serviceSuspension:
            return "RTK.channelstate.servicesuspension".localized
        case .transmitting:
            return "RTK.channelstate.transmitting".localized
        default:
            return "RTK.channelstate.unknown".localized
        }
    }
}

class ConfigureRtkHelper {
    public static func configureRtk(
        aircraft: DJIAircraft,
        config: RTKConfigurationRecord,
        withError: @escaping (_ error: Error?, _ action: String) -> Void,
        withSuccess: @escaping () -> Void
    ) {
        guard aircraft.flightController?.rtk != nil else { return }
        
        ConfigureRtkHelper(aircraft.flightController!.rtk!, config, withError, withSuccess).stopNetwork()
    }
    
    let log = OSLog(subsystem: "DronelinkDJIUI", category: "ConfigureRtkHelper")
    let rtk: DJIRTK
    let config: RTKConfigurationRecord
    let withError: (_ error: Error?, _ action: String) -> Void
    let withSuccess: () -> Void
    var last = 0
    
    private init(_ rtk: DJIRTK, _ config: RTKConfigurationRecord, _ withError: @escaping (_ error: Error?, _ action: String) -> Void, _ withSuccess: @escaping () -> Void) {
        
        self.rtk = rtk
        self.config = config
        self.withError = withError
        self.withSuccess = withSuccess
        self.last = 0
        
        stopNetwork()
    }
    private func shouldRun(_ step: Int) -> Bool
    {
        // the DJI competion blocks are called multiple times. This method ensure
        // each action is only executed once
        if last != step {
            return false
        }
        last = step + 1
        return true
    }
    private func stopNetwork() {
        if !shouldRun(0){
            return
        }
        
        os_log(.debug, log: self.log, "Stop network")
        DJISDKManager.rtkNetworkServiceProvider().stopNetworkService() { (error: Error?) in
            if self.noError(error: error, action: "Stop RTK Network Service") {
                self.enableRtk()
            }
        }
    }
    private func enableRtk() {
        if !shouldRun(1){
            return
        }
        os_log(.debug, log: self.log, "Enabled RTK")
        
        rtk.setEnabled(true) { (error: Error?) in
            // For enable: report the error but try to continue even if it fails
            self.noError(error: error, action: "Enable RTK")
            self.setSettings()
        }
    }
    private func setSettings() {
        if !shouldRun(2){
            return
        }
        os_log(.debug, log: self.log, "Set Settings")
        let settings = DJIMutableRTKNetworkServiceSettings()
        settings.mountpoint = config.mountPoint
        settings.password = config.password
        settings.port = Int32(config.port!)
        settings.serverAddress = config.serverAddress
        settings.userName = config.userName
        
        DJISDKManager.rtkNetworkServiceProvider().setNetworkServiceSettings(settings)
        
        setReferenceStation()
    }
    private func setReferenceStation() {
        if !shouldRun(3){
            return
        }
        os_log(.debug, log: self.log, "Set Reference station")
        rtk.setReferenceStationSource(.customNetworkService) { (error: Error?) in
            if self.noError(error: error, action: "Set reference station custom") {
                self.startNetwork()
            }
        }
    }
    private func startNetwork() {
        if !shouldRun(4){
            return
        }
        os_log(.debug, log: self.log, "Start network")
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
        os_log(.debug, log: self.log, "Success: %@", action)
        
        return true
    }
}
