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
        
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        view.backgroundColor = .blue
        statusLabel.text = "..."
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        view.addSubview(statusLabel)
        
        rtkLabel.text = "RTK"
        rtkLabel.textAlignment = .center
        rtkLabel.textColor = .white
        view.addSubview(rtkLabel)
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(RtkStatus.handleGesture(_:)))
        view.addGestureRecognizer(tap)
    }
    @objc private func handleGesture(_ gesture: UITapGestureRecognizer) {
        statusLabel.text="xyz"
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        let labelHeight = 30
        statusLabel.snp.remakeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        rtkLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }
    }
}
