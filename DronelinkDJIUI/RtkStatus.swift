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
    
    let statusLabel = UILabel()
    let rtkLabel = UILabel()
    private var rtkManager: DJIRTKManager?
    
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
    public func setRTK(rtk: DJIRTKManager?) {
        self.rtkManager = rtk
        
        if rtk != nil {
            rtk!.addUpdateListner(key: "RtkStatus") { (state: RTKState) in
                if (rtk!.isRtkSupported())
                {
                    self.updateLabel(state)
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
        if state.networkRTKStatus == .notSupported {
            statusLabel.text = "DJIDashboardViewController.rtk.status.na".localized
        }
        else if (state.networkRTKStatus == .disabled) {
            statusLabel.text = "DJIDashboardViewController.rtk.status.disabled".localized
        }
        else if (state.networkRTKStatus == .connecting) {
            statusLabel.text = "DJIDashboardViewController.rtk.status.connecting".localized
        }
        else if (state.networkRTKStatus == .connected) {
            statusLabel.text = "DJIDashboardViewController.rtk.status.connected".localized
        }
        else {
            statusLabel.text = state.networkServiceStateText
        }
        
    }
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        let defaultPadding = 8
        
        rtkLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalToSuperview().offset(2)
        }
        
        statusLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(rtkLabel.snp.bottom)
        }
    }
}
