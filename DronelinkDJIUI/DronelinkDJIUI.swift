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

extension DJIDroneSessionManager: WidgetFactory {
    public func createExecutorWidget(current: ExecutorWidget? = nil) -> ExecutorWidget? {
        GenericWidgetFactory.shared.createExecutorWidget(current: current)
    }
    
    public func createMainMenuWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXPreflightChecklistController ? current : DUXPreflightChecklistController().createWidget()
    }
    
    public func createCameraFeedWidget(current: Widget? = nil, primary: Bool = true) -> Widget? {
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
    
    public func createStatusBackgroundWidget(current: Widget? = nil) -> Widget? {
        GenericWidgetFactory.shared.createStatusBackgroundWidget(current: current)
    }
    
    public func createStatusForegroundWidget(current: Widget? = nil) -> Widget? {
        GenericWidgetFactory.shared.createStatusForegroundWidget(current: current)
    }
    
    public func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXRemainingFlightTimeWidget ? current : DUXRemainingFlightTimeWidget().createWidget()
    }
    
    public func createFlightModeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXFlightModeWidget ? current : DUXFlightModeWidget().createWidget()
    }
    
    public func createGPSWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXGPSSignalWidget ? current : DUXGPSSignalWidget().createWidget()
    }
    
    public func createVisionWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXVisionWidget ? current : DUXVisionWidget().createWidget()
    }
    
    public func createUplinkWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXRemoteControlSignalWidget ? current : DUXRemoteControlSignalWidget().createWidget()
    }
    
    public func createDownlinkWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXVideoSignalWidget ? current : DUXVideoSignalWidget().createWidget()
    }
    
    public func createBatteryWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXBatteryWidget ? current : DUXBatteryWidget().createWidget()
    }
    
    public func createDistanceUserWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createDistanceUserWidget(current: current) }

    public func createDistanceHomeWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createDistanceHomeWidget(current: current) }

    public func createAltitudeWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createAltitudeWidget(current: current) }

    public func createHorizontalSpeedWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createHorizontalSpeedWidget(current: current) }

    public func createVerticalSpeedWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createVerticalSpeedWidget(current: current) }
    
    public func createCameraGeneralSettingsWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXCameraSettingsController ? current : DUXCameraSettingsController().createWidget()
    }
    
    public func createCameraExposureWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXCameraConfigInfoWidget ? current : DUXCameraConfigInfoWidget().createWidget()
    }
    
    public func createCameraStorageWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXCameraConfigStorageWidget ? current : DUXCameraConfigStorageWidget().createWidget()
    }
    
    public func createCameraAutoExposureWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXAutoExposureSwitchWidget ? current : DUXAutoExposureSwitchWidget().createWidget()
    }
    
    public func createCameraExposureFocusWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXExposureFocusSwitchWidget ? current : DUXExposureFocusSwitchWidget().createWidget()
    }
    
    public func createCameraFocusModeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXFocusModeWidget ? current : DUXFocusModeWidget().createWidget()
    }
    
    public func createCameraModeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXPictureVideoSwitchWidget ? current : DUXPictureVideoSwitchWidget().createWidget()
    }
    
    public func createCameraCaptureWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXCaptureWidget ? current : DUXCaptureWidget().createWidget()
    }
    
    public func createCameraExposureSettingsWidget(current: Widget? = nil) -> Widget? {
        (current as? WrapperWidget)?.viewController is DUXExposureSettingsController ? current : DUXExposureSettingsController().createWidget()
    }
    
    public func createCompassWidget(current: Widget?) -> Widget? {
        if current?.view.subviews.first is DUXCompassWidget {
            return current
        }
        
        return DUXCompassWidget().createWidget()
    }
    
    public func createTelemetryWidget(current: Widget? = nil) -> Widget? { GenericWidgetFactory.shared.createTelemetryWidget(current: current) }
    
    public func createRTKStatusWidget(current: Widget? = nil) -> Widget? {
        if let session = session as? DJIDroneSession {
            let widget = RTKStatusWidget()
            widget.set(manager: DJIRTKManager(session.adapter.drone))
            return widget
        }
        
        return nil
    }
    
    public func createRTKSettingsWidget(current: Widget? = nil) -> Widget? {
        if let session = session as? DJIDroneSession {
            let widget = RTKSettingsWidget()
            widget.set(manager: DJIRTKManager(session.adapter.drone))
            return widget
        }
        
        return nil
    }
}
