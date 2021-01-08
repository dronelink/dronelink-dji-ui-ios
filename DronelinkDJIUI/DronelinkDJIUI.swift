//
//  DronelinkDJIUI.swift
//  DronelinkDJIUI
//
//  Created by Jim McAndrew on 10/29/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore
import DronelinkCoreUI
import DronelinkDJI
import DJIUXSDK

extension DronelinkDJIUI {
    public static let shared = DronelinkDJIUI()
    public static let bundle = Bundle.init(for: DronelinkDJIUI.self)
    public static func loadImage(named: String, renderingMode: UIImage.RenderingMode = .alwaysTemplate) -> UIImage? {
        return UIImage(named: named, in: DronelinkDJIUI.bundle, compatibleWith: nil)?.withRenderingMode(renderingMode)
    }
}

public class DronelinkDJIUI: NSObject {
}

extension DJIDroneSessionManager: WidgetFactoryProvider {
    public var widgetFactory: WidgetFactory? { DJIWidgetFactory(session: session) }
}

open class DJIWidgetFactory: WidgetFactory {
    open override func createMainMenuWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXPreflightChecklistController ? current : DUXPreflightChecklistController().createWidget()
    }

    open override func createCameraFeedWidget(current: Widget? = nil, primary: Bool = true) -> Widget? {
        if session == nil {
            return nil
        }

        if let current = current as? WrapperWidget, let fpvViewController = current.viewController as? DUXFPVViewController {
            fpvViewController.isHUDInteractionEnabled = primary
            fpvViewController.isRadarWidgetVisible = primary
            return current
        }

        let fpvViewController = DUXFPVViewController()
        let widget = fpvViewController.createWidget()
        fpvViewController.isHUDInteractionEnabled = primary
        fpvViewController.isRadarWidgetVisible = primary
        fpvViewController.fpvView?.showCameraDisplayName = false

        return widget
    }

    open override func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXRemainingFlightTimeWidget ? current : DUXRemainingFlightTimeWidget().createWidget()
    }

    open override func createVisionWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXVisionWidget ? current : DUXVisionWidget().createWidget()
    }
    
    open override var cameraMenuWidgetEnabled: Bool { true }

    open override func createCameraMenuWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXCameraSettingsController ? current : DUXCameraSettingsController().createWidget()
    }

    open override func createCameraExposureWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXCameraConfigInfoWidget ? current : DUXCameraConfigInfoWidget().createWidget()
    }

    open override func createCameraStorageWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXCameraConfigStorageWidget ? current : DUXCameraConfigStorageWidget().createWidget()
    }

    open override func createCameraAutoExposureWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXAutoExposureSwitchWidget ? current : DUXAutoExposureSwitchWidget().createWidget()
    }

    open override func createCameraExposureFocusWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXExposureFocusSwitchWidget ? current : DUXExposureFocusSwitchWidget().createWidget()
    }

    open override func createCameraFocusModeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXFocusModeWidget ? current : DUXFocusModeWidget().createWidget()
    }

    open override var cameraExposureMenuWidgetEnabled: Bool { true }
    
    open override func createCameraExposureMenuWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXExposureSettingsController ? current : DUXExposureSettingsController().createWidget()
    }

    open override func createCompassWidget(current: Widget?) -> Widget? {
        if current?.view.subviews.first is DUXCompassWidget {
            return current
        }

        return DUXCompassWidget().createWidget()
    }

    open override func createRTKStatusWidget(current: Widget? = nil) -> Widget? {
        if (current is RTKStatusWidget) {
            return current
        }
        
        let widget = RTKStatusWidget()
        widget.createManager = {
            if let session = self.session as? DJIDroneSession {
                return DJIRTKManager(session.adapter.drone)
            }
            return nil
        }
        return widget
    }

    open override func createRTKMenuWidget(current: Widget? = nil) -> Widget? {
        RTKSettingsWidget()
    }
}
