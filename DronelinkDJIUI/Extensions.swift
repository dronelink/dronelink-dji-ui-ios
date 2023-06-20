//
//  Extensions.swift
//  DronelinkDJIUI
//
//  Created by Jim McAndrew on 10/29/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//

import Foundation
import DronelinkCore


extension String {
    internal static let LocalizationMissing = "MISSING STRING LOCALIZATION"
    
    var localized: String {
        let value = self.localizeForLibrary(libraryBundle: DronelinkDJIUI.bundle, mainBundle: Bundle.main)
        return value
    }
}
