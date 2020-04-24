//
//  DronelinkDJIUI.swift
//  DronelinkDJIUI
//
//  Created by Jim McAndrew on 10/29/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import Foundation
import UIKit

extension DronelinkDJIUI {
    public static let shared = DronelinkDJIUI()
    public static let bundle = Bundle.init(for: DronelinkDJIUI.self)
    public static func loadImage(named: String, renderingMode: UIImage.RenderingMode = .alwaysTemplate) -> UIImage? {
        return UIImage(named: named, in: DronelinkDJIUI.bundle, compatibleWith: nil)?.withRenderingMode(renderingMode)
    }
}

public class DronelinkDJIUI: NSObject {
}
