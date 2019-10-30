//
//  Extensions.swift
//  DronelinkDJIUI
//
//  Created by Jim McAndrew on 10/29/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//

import Foundation

extension String {
    internal static let LocalizationMissing = "MISSING STRING LOCALIZATION"
    
    var localized: String {
        let value = DronelinkDJIUI.bundle.localizedString(forKey: self, value: String.LocalizationMissing, table: nil)
        assert(value != String.LocalizationMissing, "String localization missing: \(self)")
        return value
    }
}
