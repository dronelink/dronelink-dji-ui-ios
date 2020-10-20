//
//  RtkStatus.swift
//  DronelinkDJIUI
//
//  Created by Patrick Verbeeten on 10/10/2020.
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
import Kingfisher
import SwiftyUserDefaults

class RTKStatus : UIViewController {
    
    private var droneSessionManager: DroneSessionManager!
    
    let statusLabel = UILabel()
    let rtkLabel = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        rtkLabel.font = rtkLabel.font.withSize(9)
        rtkLabel.text = "DJIDashboardViewController.rtk.status.label".localized
        rtkLabel.textAlignment = .left
        rtkLabel.textColor = .lightGray
        view.addSubview(rtkLabel)
        
        statusLabel.text = "DJIDashboardViewController.rtk.status.na".localized
        statusLabel.textAlignment = .left
        statusLabel.textColor = .white
        statusLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(statusLabel)
    }
    public func setSession(session: DroneSession) {
        if let dji = session as? DJIDroneSession {
            dji.rtk.addUpdateListner(key: "RtkStatus") { (state: RtkState) in
                if (dji.rtk.isSupported())
                {
                    self.updateLabel(rtk)
                    self.view.isHidden = false
                }
                else {
                    self.view.isHidden = true
                }
            }
        }
        else {
            self.view.isHidden = true
        }
    }
    func updateLabel(_ state: RTKState) {
        if (!state.networkRTKEnabled) {
            statusLabel.text = "DJIDashboardViewController.rtk.status.disabled".localized
        }
        else if (state.networkRTKConnected) {
            statusLabel.text = "DJIDashboardViewController.rtk.status.connected".localized
        }
        else if state.networkServiceState != nil {
            statusLabel.text = state.networkServiceStateText
        }
        else {
            statusLabel.text = "DJIDashboardViewController.rtk.status.na".localized
        }
        
    }
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        rtkLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(2)
        }
        
        statusLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(8)
            make.top.equalTo(rtkLabel.snp.bottom)
        }
    }
}
