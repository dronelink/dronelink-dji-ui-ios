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

class RtkStatus : UIViewController, DJIRTKDelegate {
    
    private var droneSessionManager: DroneSessionManager!
    
    let statusLabel = UILabel()
    let rtkLabel = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        rtkLabel.font = rtkLabel.font.withSize(9)
        rtkLabel.text = "RTK"
        rtkLabel.textAlignment = .left
        rtkLabel.textColor = .lightGray
        view.addSubview(rtkLabel)
        
        statusLabel.text = "..."
        statusLabel.textAlignment = .left
        statusLabel.textColor = .white
        view.addSubview(statusLabel)
        
        onProductConnection(product: DJISDKManager.product())
        
        DJISDKManager.startListeningOnProductConnectionUpdates(withListener: "x") { (product) in self.onProductConnection(product: product)
        }
    }
    func onProductConnection(product: DJIBaseProduct?) {
        if let aircraft = product as? DJIAircraft {
            statusLabel.text = "n/a"
            aircraft.flightController?.rtk?.delegate = self;
        }
        else {
            statusLabel.text = "..."
        }
    }
    @objc func didUpdateState(_ sender: DJIRTK, state: DJIRTKState)
    {
        if state.positioningSolution == .none {
            statusLabel.text = "none"
        }
        else if state.positioningSolution == .float {
            statusLabel.text = "float"
        }
        else if state.positioningSolution == .singlePoint {
            statusLabel.text = "single"
        }
        else if state.positioningSolution == .fixedPoint {
            statusLabel.text = "fixed"
        }
        else {
            statusLabel.text = "?"
        }
        
    }
    
    @objc func handleGesture(_ sender: UITapGestureRecognizer) {
        statusLabel.text="xyz"
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        rtkLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(2)
            make.top.equalToSuperview().offset(2)
        }
        
        statusLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(2)
            make.top.equalTo(rtkLabel.snp.bottom)
        }
    }
}
