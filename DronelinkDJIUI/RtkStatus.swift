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

class RtkStatus : UIViewController {
    
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
        
        RtkManager.instance.addUpdateListner(key: "RtkStatus") { (state: RtkState) in
            let rtk = true //RtkManager.instance.isRtkSupported()
            if rtk {
                self.updateLabel(state)
                self.view.isHidden = false
            }
            else {
                self.view.isHidden = true
                
            }
        }
    }
    
    func updateLabel(_ state: RtkState) {
        if state.state != nil && state.state?.positioningSolution != DJIRTKPositioningSolution.none {
            statusLabel.text = state.positioningSolutionText
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
