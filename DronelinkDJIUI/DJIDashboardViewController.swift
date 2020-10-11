//
//  DashboardViewController.swift
//  DronelinkDJIUI
//
//  Created by Jim McAndrew on 1/15/19.
//  Copyright © 2019 Dronelink. All rights reserved.
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

extension DefaultsKeys {
    var legacyDeviceWarningViewed: DefaultsKey<Bool> { .init("legacyDeviceWarningViewed", defaultValue: false) }
    var mapType: DefaultsKey<String> { .init("mapType", defaultValue: Device.legacy ? MapType.mapbox.rawValue : MapType.microsoft.rawValue) }
}

private enum MapType: String {
    case mapbox = "mapbox", microsoft = "microsoft"
}

public protocol DJIDashboardViewControllerDelegate {
    func onDashboardDismissed()
}

public class DJIDashboardViewController: UIViewController {
    public static func create(droneSessionManager: DJIDroneSessionManager, mapCredentialsKey: String, delegate: DJIDashboardViewControllerDelegate? = nil) -> DJIDashboardViewController {
        let dashboardViewController = DJIDashboardViewController()
        dashboardViewController.mapCredentialsKey = mapCredentialsKey
        dashboardViewController.modalPresentationStyle = .fullScreen
        dashboardViewController.droneSessionManager = droneSessionManager
        dashboardViewController.delegate = delegate
        return dashboardViewController
    }
    
    private var delegate: DJIDashboardViewControllerDelegate?
    private var droneSessionManager: DJIDroneSessionManager!
    private var session: DroneSession?
    private var missionExecutor: MissionExecutor?
    private var funcExecutor: FuncExecutor?
    private var overlayViewController: UIViewController?
    private let hideOverlayButton = UIButton(type: .custom)
    private var mapViewController: UIViewController!
    private var mapCredentialsKey = ""
    private let primaryViewToggleButton = UIButton(type: .custom)
    private let mapMoreButton = UIButton(type: .custom)
    private let dismissButton = UIButton(type: .custom)
    private let videoPreviewerViewController = DUXFPVViewController()
    private var videoPreviewerView = UIView()
    private let reticalImageView = UIImageView()
    private let topBarBackgroundView = UIView()
    private let preflightButton = UIButton(type: .custom)
    private let preflightStatusWidget = DUXPreFlightStatusWidget()
    private let remainingFlightTimeWidget = DUXRemainingFlightTimeWidget()
    private let statusWidgets: [(view: UIView, widthRatio: CGFloat)] = [
        (view: DUXBatteryWidget(), widthRatio: 2.75),
        (view: DUXVideoSignalWidget(), widthRatio: 2.75),
        (view: DUXRemoteControlSignalWidget(), widthRatio: 2.5),
        (view: DUXVisionWidget(), widthRatio: 1.35),
        (view: DUXGPSSignalWidget(), widthRatio: 1.75),
        (view: DUXFlightModeWidget(), widthRatio: 4.5)
    ]
    private let menuButton = UIButton(type: .custom)
    private let exposureButton = UIButton(type: .custom)
    private let offsetsButton = UIButton(type: .custom)
    private let autoExposureSwitchWidget = DUXAutoExposureSwitchWidget()
    private let exposureFocusSwitchWidget = DUXExposureFocusSwitchWidget()
    private let focusModeWidget = DUXFocusModeWidget()
    private let cameraConfigStorageWidget = DUXCameraConfigStorageWidget()
    private let cameraConfigInfoWidget = DUXCameraConfigInfoWidget()
    private let pictureVideoSwitchWidget = DUXPictureVideoSwitchWidget()
    private let captureWidget = DUXCaptureWidget()
    private let captureBackgroundView = UIView()
    private let compassWidget = DUXCompassWidget()
    
    private var interfaceVisible = true
    private var telemetryViewController: TelemetryViewController?
    private var droneOffsetsViewController1: DroneOffsetsViewController?
    private var droneOffsetsViewController2: DroneOffsetsViewController?
    private var cameraOffsetsViewController: CameraOffsetsViewController?
    private var missionViewController: MissionViewController?
    private var missionExpanded: Bool { missionViewController?.expanded ?? false }
    private var funcViewController: FuncViewController?
    private var funcExpanded = false
    private var primaryViewToggled = false
    private var videoPreviewerPrimary = true
    private let defaultPadding = 10
    private var primaryView: UIView { return !interfaceVisible || videoPreviewerPrimary || portrait ? videoPreviewerView : mapViewController.view }
    private var secondaryView: UIView { return primaryView == videoPreviewerView ? mapViewController.view : videoPreviewerView }
    private var portrait: Bool { return UIScreen.main.bounds.width < UIScreen.main.bounds.height }
    private var tablet: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    private var statusWidgetHeight: CGFloat { return tablet ? 50 : 40 }
    private var offsetsButtonEnabled = false
    private let rtkStatus = RtkStatus()
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        videoPreviewerPrimary = droneSessionManager.session != nil
        
        view.backgroundColor = UIColor.black
        
        hideOverlayButton.addTarget(self, action: #selector(onHideOverlay(sender:)), for: .touchUpInside)
        view.addSubview(hideOverlayButton)
        
        addChild(videoPreviewerViewController)
        videoPreviewerViewController.didMove(toParent: self)
            
        videoPreviewerView = videoPreviewerViewController.view
        videoPreviewerView.addShadow()
        videoPreviewerView.backgroundColor = UIColor(displayP3Red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        view.addSubview(videoPreviewerView)
        
        reticalImageView.isUserInteractionEnabled = false
        reticalImageView.contentMode = .scaleAspectFit
        view.addSubview(reticalImageView)
        
        topBarBackgroundView.backgroundColor = DronelinkUI.Constants.overlayColor
        view.addSubview(topBarBackgroundView)
        
        view.addSubview(preflightStatusWidget)
        
        for statusWidget in statusWidgets {
            view.addSubview(statusWidget.view)
        }
        
        focusModeWidget.addShadow()
        view.addSubview(focusModeWidget)
        
        exposureFocusSwitchWidget.addShadow()
        view.addSubview(exposureFocusSwitchWidget)
        
        autoExposureSwitchWidget.addShadow()
        view.addSubview(autoExposureSwitchWidget)
        
        cameraConfigStorageWidget.addShadow()
        view.addSubview(cameraConfigStorageWidget)
        
        cameraConfigInfoWidget.addShadow()
        view.addSubview(cameraConfigInfoWidget)
        
        view.addSubview(preflightButton)
        preflightButton.addTarget(self, action: #selector(onPreflight(sender:)), for: .touchUpInside)
        
        view.addSubview(remainingFlightTimeWidget)

        addChild(rtkStatus)
        view.addSubview(rtkStatus.view)
        
        captureBackgroundView.addShadow()
        captureBackgroundView.backgroundColor = DronelinkUI.Constants.overlayColor
        captureBackgroundView.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.addSubview(captureBackgroundView)
        
        menuButton.setTitle("DJIDashboardViewController.menu".localized, for: .normal)
        menuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        menuButton.addTarget(self, action: #selector(onMenu(sender:)), for: .touchUpInside)
        view.addSubview(menuButton)
        
        view.addSubview(pictureVideoSwitchWidget)
        view.addSubview(captureWidget)
        
        exposureButton.tintColor = UIColor.white
        exposureButton.setImage(DronelinkDJIUI.loadImage(named: "baseline_tune_white_36pt"), for: .normal)
        exposureButton.addTarget(self, action: #selector(onExposureSettings(sender:)), for: .touchUpInside)
        view.addSubview(exposureButton)
        
        offsetsButton.isHidden = !offsetsButtonEnabled
        offsetsButton.setImage(DronelinkDJIUI.loadImage(named: "baseline_control_camera_white_36pt"), for: .normal)
        offsetsButton.addTarget(self, action: #selector(onOffsets(sender:)), for: .touchUpInside)
        view.addSubview(offsetsButton)
        
        view.addSubview(compassWidget)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkDJIUI.loadImage(named: "dronelink-logo"), for: .normal)
        dismissButton.imageView?.contentMode = .scaleAspectFit
        dismissButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        dismissButton.addTarget(self, action: #selector(onDismiss(sender:)), for: .touchUpInside)
        view.addSubview(dismissButton)
        
        if Device.legacy {
            if !Defaults[\.legacyDeviceWarningViewed] {
                Defaults[\.legacyDeviceWarningViewed] = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    DronelinkUI.shared.showDialog(
                        title: "DJIDashboardViewController.device.legacy.title".localized,
                        details: "DJIDashboardViewController.device.legacy.details".localized,
                        actions: [
                            MDCAlertAction(title: "DJIDashboardViewController.device.legacy.confirm".localized, emphasis: .high, handler: { action in
                            })
                        ])
                }
            }
        }
        
        switch Defaults[\.mapType] {
        case MapType.microsoft.rawValue:
            updateMapMicrosoft()
            break
            
        case MapType.mapbox.rawValue:
            updateMapMapbox()
            break
            
        default:
            updateMapMapbox()
            break
        }
        
        primaryViewToggleButton.tintColor = UIColor.white
        primaryViewToggleButton.setImage(DronelinkDJIUI.loadImage(named: "vector-arrange-below"), for: .normal)
        primaryViewToggleButton.addTarget(self, action: #selector(onPrimaryViewToggle(sender:)), for: .touchUpInside)
        view.addSubview(primaryViewToggleButton)
        
        mapMoreButton.tintColor = UIColor.white
        mapMoreButton.setImage(DronelinkDJIUI.loadImage(named: "outline_layers_white_36pt"), for: .normal)
        mapMoreButton.addTarget(self, action: #selector(onMapMore(sender:)), for: .touchUpInside)
        view.addSubview(mapMoreButton)
        
        let telemetryViewController = TelemetryViewController.create(droneSessionManager: self.droneSessionManager)
        addChild(telemetryViewController)
        view.addSubview(telemetryViewController.view)
        telemetryViewController.didMove(toParent: self)
        self.telemetryViewController = telemetryViewController
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(onShowInterface))
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 3
        videoPreviewerView.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(onHideInterface))
        swipeUp.direction = .up
        swipeUp.numberOfTouchesRequired = 3
        videoPreviewerView.addGestureRecognizer(swipeUp)
        
        let tapRtk = UITapGestureRecognizer(target: self, action: #selector(onRtkConfiguration))
        rtkStatus.view.addGestureRecognizer(tapRtk)
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dronelink.shared.add(delegate: self)
        droneSessionManager?.add(delegate: self)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Dronelink.shared.remove(delegate: self)
        droneSessionManager?.remove(delegate: self)
        session?.remove(delegate: self)
        missionExecutor?.remove(delegate: self)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.setNeedsUpdateConstraints()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        updateConstraints()
    }
    
    func updateConstraints() {
        view.sendSubviewToBack(reticalImageView)
        view.sendSubviewToBack(primaryView)
        view.bringSubviewToFront(secondaryView)
        view.bringSubviewToFront(primaryViewToggleButton)
        view.bringSubviewToFront(mapMoreButton)
        view.bringSubviewToFront(compassWidget)
        view.bringSubviewToFront(rtkStatus.view)
        
        if let telemetryView = telemetryViewController?.view {
            view.bringSubviewToFront(telemetryView)
        }
        
        videoPreviewerViewController.isHUDInteractionEnabled = primaryView == videoPreviewerView
        videoPreviewerViewController.isRadarWidgetVisible = primaryView == videoPreviewerView
        videoPreviewerViewController.fpvView?.showCameraDisplayName = false
        primaryView.snp.remakeConstraints { make in
            if (portrait && !tablet) {
                make.top.equalTo(topBarBackgroundView.safeAreaLayoutGuide.snp.bottom).offset(statusWidgetHeight * 2)
            }
            else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
            
            if (portrait) {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(UIScreen.main.bounds.width * 2/3)
            }
            else {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        
        secondaryView.snp.remakeConstraints { make in
            if (portrait) {
                make.top.equalTo(primaryView.snp.bottom).offset(tablet ? 0 : statusWidgetHeight * 2)
                make.right.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            else {
                if tablet {
                    make.width.equalTo(view.snp.width).multipliedBy(funcViewController == nil || !funcExpanded ? 0.4 : 0.30)
                }
                else {
                    make.width.equalTo(view.snp.width).multipliedBy(funcViewController == nil || !funcExpanded ? 0.28 : 0.18)
                }
                
                make.height.equalTo(secondaryView.snp.width).multipliedBy(0.5)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                if !portrait, funcExpanded, let funcViewController = funcViewController {
                    make.left.equalTo(funcViewController.view.snp.right).offset(defaultPadding)
                }
                else {
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                }
            }
        }
        
        reticalImageView.snp.remakeConstraints { make in
            make.center.equalTo(videoPreviewerView)
            make.height.equalTo(videoPreviewerView)
        }
        
        primaryViewToggleButton.isHidden = portrait
        primaryViewToggleButton.snp.remakeConstraints { make in
            make.left.equalTo(secondaryView.snp.left).offset(defaultPadding)
            make.top.equalTo(secondaryView.snp.top).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        mapMoreButton.snp.remakeConstraints { make in
            make.left.equalTo(primaryViewToggleButton)
            make.top.equalTo(portrait ? secondaryView.snp.top : primaryViewToggleButton.snp.bottom).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        topBarBackgroundView.snp.remakeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(statusWidgetHeight)
        }
        
        dismissButton.isEnabled = !(missionExecutor?.engaged ?? false)
        dismissButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(topBarBackgroundView.snp.top)
            make.width.equalTo(statusWidgetHeight * 1.25)
            make.height.equalTo(statusWidgetHeight)
        }
        
        preflightButton.snp.remakeConstraints { make in
            make.edges.equalTo(topBarBackgroundView)
        }
        
        var statusWidgetPrevious: UIView?
        for statusWidget in statusWidgets {
            statusWidget.view.snp.remakeConstraints { make in
                let paddingRight: CGFloat = 5
                if let statusWidgetPrevious = statusWidgetPrevious {
                    make.right.equalTo(statusWidgetPrevious.snp.left).offset(-paddingRight)
                }
                else {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-paddingRight)
                }
                let topPadding: CGFloat = 0.25
                make.top.equalTo(topBarBackgroundView.snp.top).offset((portrait && !tablet ? statusWidgetHeight : 0) + (statusWidgetHeight * topPadding))
                let height = statusWidgetHeight * (1 - (2 * topPadding))
                make.height.equalTo(height)
                make.width.equalTo(statusWidget.view.snp.height).multipliedBy(statusWidget.widthRatio)
                
            }
            statusWidgetPrevious = statusWidget.view
        }
        
        preflightStatusWidget.snp.remakeConstraints { make in
            make.top.equalTo(topBarBackgroundView.snp.top)
            make.left.equalTo(dismissButton.snp.right).offset(defaultPadding)
            make.height.equalTo(topBarBackgroundView.snp.height)
            if (portrait && !tablet) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
            }
            else {
                make.right.equalTo(statusWidgets.last!.view.snp.left).offset(-defaultPadding)
            }
        }
        
        let cameraWidgetSize = statusWidgetHeight * 0.65
        focusModeWidget.snp.remakeConstraints { make in
            make.top.equalTo(statusWidgets[0].view.snp.bottom).offset(portrait && !tablet ? 14 : 20)
            make.right.equalToSuperview().offset(portrait && !tablet ? -5 : -defaultPadding)
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(cameraWidgetSize)
        }
        
        exposureFocusSwitchWidget.snp.remakeConstraints { make in
            make.top.equalTo(focusModeWidget.snp.top)
            make.right.equalTo(focusModeWidget.snp.left)
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(cameraWidgetSize)
        }
        
        autoExposureSwitchWidget.snp.remakeConstraints { make in
            make.top.equalTo(focusModeWidget.snp.top)
            make.right.equalTo(exposureFocusSwitchWidget.snp.left)
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(cameraWidgetSize)
        }
        
        cameraConfigStorageWidget.snp.remakeConstraints { make in
            make.top.equalTo(focusModeWidget.snp.top)
            make.right.equalTo(autoExposureSwitchWidget.snp.left).offset(-defaultPadding)
            make.height.equalTo(cameraWidgetSize)
        }
        
        cameraConfigInfoWidget.snp.remakeConstraints { make in
            make.top.equalTo(focusModeWidget.snp.top)
            make.right.equalTo(cameraConfigStorageWidget.snp.left).offset(-defaultPadding)
            make.height.equalTo(cameraWidgetSize)
        }
        rtkStatus.view.snp.remakeConstraints { make in
            make.top.equalTo(focusModeWidget.snp.top)
            make.right.equalTo(cameraConfigInfoWidget.snp.left).offset(-defaultPadding)
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(60)
        }
        
        remainingFlightTimeWidget.snp.remakeConstraints { make in
            let topOffset = -9
            if (portrait) {
                make.top.equalTo(videoPreviewerView.snp.top).offset(topOffset)
            }
            else {
                make.top.equalTo(topBarBackgroundView.snp.bottom).offset(topOffset)
            }
            make.left.equalTo(videoPreviewerView.snp.left)
            make.right.equalTo(videoPreviewerView.snp.right)
        }
        
        //        trailingBarViewController.view.snp.remakeConstraints { make in
        //            make.centerY.equalTo(primaryView.snp.centerY)
        //            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
        //            make.width.equalTo(55)
        //            make.height.equalTo(240)
        //        }
        
        captureBackgroundView.snp.remakeConstraints { make in
            make.top.equalTo(menuButton.snp.top)
            make.right.equalTo(primaryView.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
            make.left.equalTo(captureWidget.snp.left).offset(-defaultPadding)
            make.bottom.equalTo((offsetsButtonEnabled ? offsetsButton : exposureButton).snp.bottom).offset(15)
        }
        
        captureWidget.snp.remakeConstraints { make in
            if (portrait || tablet) {
                make.centerY.equalTo(primaryView.snp.centerY).offset(4)
            }
            else {
                make.top.equalTo(cameraConfigInfoWidget.snp.bottom).offset(128)
            }
            make.right.equalTo(captureBackgroundView.snp.right).offset(-defaultPadding)
            make.height.equalTo(60)
            make.width.equalTo(49)
        }
        
        pictureVideoSwitchWidget.snp.remakeConstraints { make in
            make.bottom.equalTo(captureWidget.snp.top).offset(-12)
            make.centerX.equalTo(captureWidget.snp.centerX)
            make.height.equalTo(45)
            make.width.equalTo(56)
        }
        
        menuButton.snp.remakeConstraints { make in
            make.bottom.equalTo(pictureVideoSwitchWidget.snp.top)
            make.centerX.equalTo(captureWidget.snp.centerX)
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        
        exposureButton.snp.remakeConstraints { make in
            make.top.equalTo(captureWidget.snp.bottom).offset(defaultPadding)
            make.centerX.equalTo(captureWidget.snp.centerX)
            make.height.equalTo(28)
            make.width.equalTo(28)
        }
        
        offsetsButton.isHidden = !offsetsButtonEnabled
        offsetsButton.tintColor = droneOffsetsViewController1 == nil ? UIColor.white : DronelinkUI.Constants.secondaryColor
        offsetsButton.snp.remakeConstraints { make in
            make.top.equalTo(exposureButton.snp.bottom).offset(15)
            make.centerX.equalTo(captureWidget.snp.centerX)
            make.height.equalTo(28)
            make.width.equalTo(28)
        }
        
        compassWidget.snp.remakeConstraints { make in
            if (portrait && tablet) {
                make.bottom.equalTo(secondaryView.snp.top).offset(-defaultPadding)
                make.height.equalTo(primaryView.snp.width).multipliedBy(0.15)
                make.right.equalTo(captureBackgroundView.snp.right)
                make.width.equalTo(compassWidget.snp.height)
                return
            }
            
            if (portrait) {
                make.bottom.equalTo(secondaryView.snp.top).offset(-5)
                make.height.equalTo(compassWidget.snp.width)
                make.centerX.equalTo(captureBackgroundView.snp.centerX)
                make.width.equalTo(captureBackgroundView.snp.width)
                return
            }
            
            make.bottom.equalTo(secondaryView.snp.bottom)
            make.height.equalTo(primaryView.snp.width).multipliedBy(tablet ? 0.12 : 0.09)
            make.right.equalTo(tablet ? captureBackgroundView.snp.right : captureBackgroundView.snp.left).offset(tablet ? 0 : -defaultPadding)
            make.width.equalTo(compassWidget.snp.height)
        }
        
        telemetryViewController?.view.snp.remakeConstraints { make in
            if (portrait) {
                make.bottom.equalTo(secondaryView.snp.top).offset(tablet ? -defaultPadding : -2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            }
            else {
                make.bottom.equalTo(secondaryView.snp.bottom)
                make.left.equalTo(secondaryView.snp.right).offset(defaultPadding)
            }
            make.height.equalTo(tablet ? 85 : 75)
            make.width.equalTo(tablet ? 350 : 275)
        }
        
        if let droneOffsetsViewController1 = droneOffsetsViewController1 {
            view.bringSubviewToFront(droneOffsetsViewController1.view)
            droneOffsetsViewController1.view.snp.remakeConstraints { make in
                make.height.equalTo(240)
                make.width.equalTo(200)
                if portrait {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                    make.top.equalTo(secondaryView.snp.top).offset(defaultPadding)
                }
                else {
                    make.right.equalTo(captureBackgroundView.snp.left).offset(-defaultPadding)
                    make.top.equalTo(cameraConfigInfoWidget.snp.bottom).offset(defaultPadding)
                }
            }
            
            if let droneOffsetsViewController2 = droneOffsetsViewController2 {
                view.bringSubviewToFront(droneOffsetsViewController2.view)
                droneOffsetsViewController2.view.snp.remakeConstraints { make in
                    make.height.equalTo(droneOffsetsViewController1.view)
                    make.width.equalTo(droneOffsetsViewController1.view)
                    make.right.equalTo(droneOffsetsViewController1.view)
                    make.top.equalTo(droneOffsetsViewController1.view.snp.bottom).offset(defaultPadding)
                }
            }
            
            if let cameraOffsetsViewController = cameraOffsetsViewController {
                view.bringSubviewToFront(cameraOffsetsViewController.view)
                cameraOffsetsViewController.view.snp.remakeConstraints { make in
                    make.height.equalTo(65)
                    make.width.equalTo(droneOffsetsViewController1.view)
                    make.right.equalTo(droneOffsetsViewController1.view)
                    make.top.equalTo((droneOffsetsViewController2 ?? droneOffsetsViewController1).view.snp.bottom).offset(defaultPadding)
                }
            }
        }
        
        updateConstraintsMission()
        updateConstraintsFunc()
        updateConstraintsOverlay()
        
        if !interfaceVisible && !portrait {
            videoPreviewerViewController.isHUDInteractionEnabled = false
            videoPreviewerViewController.isRadarWidgetVisible = false
            view.bringSubviewToFront(videoPreviewerView)
        }
    }
    
    func updateConstraintsMission() {
        if let missionViewController = missionViewController {
            view.bringSubviewToFront(missionViewController.view)
            missionViewController.view.snp.remakeConstraints { make in
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalToSuperview().multipliedBy(0.35)
                    if (missionExpanded) {
                        make.top.equalTo(secondaryView.snp.top).offset(defaultPadding)
                    }
                    else {
                        make.height.equalTo(80)
                    }
                    return
                }
                
                if (portrait) {
                    make.right.equalToSuperview()
                    make.left.equalToSuperview()
                    make.bottom.equalToSuperview()
                    if (missionExpanded) {
                        make.height.equalTo(secondaryView.snp.height).multipliedBy(0.5)
                    }
                    else {
                        make.height.equalTo(100)
                    }
                    return
                }
                
                make.top.equalTo(topBarBackgroundView.snp.bottom).offset(defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                if (tablet) {
                    make.width.equalTo(350)
                }
                else {
                    make.width.equalToSuperview().multipliedBy(0.4)
                }
                
                if (missionExpanded) {
                    if (tablet) {
                        make.height.equalTo(180)
                    }
                    else {
                        make.bottom.equalTo(secondaryView.snp.top).offset(-Double(defaultPadding) * 1.5)
                    }
                }
                else {
                    make.height.equalTo(80)
                }
            }
        }
    }
    
    func updateConstraintsFunc() {
        if let funcViewController = funcViewController {
            view.bringSubviewToFront(funcViewController.view)
            funcViewController.view.snp.remakeConstraints { make in
                let large = tablet || portrait
                if (funcExpanded) {
                    if (portrait) {
                        make.height.equalTo(tablet ? 550 : 300)
                    }
                    else {
                        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    }
                }
                else {
                    make.height.equalTo(185)
                }
                
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalTo(large ? 350 : 310)
                    return
                }
                
                if (portrait) {
                    make.right.equalToSuperview()
                    make.left.equalToSuperview()
                    make.top.equalTo(secondaryView.snp.top)
                    return
                }
                
                make.top.equalTo(topBarBackgroundView.snp.bottom).offset(defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalTo(large ? 350 : 310)
            }
        }
    }
    
    func updateConstraintsOverlay() {
        view.bringSubviewToFront(hideOverlayButton)
        if let overlayView = overlayViewController?.view {
            view.bringSubviewToFront(overlayView)
            overlayView.snp.remakeConstraints { make in
                let bounds = UIScreen.main.bounds
                let width = min(bounds.width - 30, max(bounds.width / 2, 400))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(width)
                make.height.equalTo(min(bounds.height - 125, width))
            }
        }
        
        hideOverlayButton.isHidden = overlayViewController == nil
        hideOverlayButton.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func onPrimaryViewToggle(sender: Any) {
        primaryViewToggled = true
        videoPreviewerPrimary = !videoPreviewerPrimary
        updateConstraints()
        view.animateLayout()
    }
    
    private func updateMapMicrosoft() {
        Defaults[\.mapType] = MapType.microsoft.rawValue
        
        if let mapViewController = mapViewController {
            mapViewController.view.removeFromSuperview()
            mapViewController.removeFromParent()
        }
        
        let mapViewController = MicrosoftMapViewController.create(droneSessionManager: droneSessionManager, credentialsKey: mapCredentialsKey)
        self.mapViewController = mapViewController
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        view.setNeedsUpdateConstraints()
    }
    
    private func updateMapMapbox() {
        Defaults[\.mapType] = MapType.mapbox.rawValue
        
        if let mapViewController = mapViewController {
            mapViewController.view.removeFromSuperview()
            mapViewController.removeFromParent()
        }
        
        let mapViewController = MapboxMapViewController.create(droneSessionManager: droneSessionManager)
        self.mapViewController = mapViewController
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        view.setNeedsUpdateConstraints()
    }
    	
    @objc func onMapMore(sender: Any) {
        if let mapViewController = mapViewController as? MicrosoftMapViewController {
            mapViewController.onMore(sender: sender, actions: [
                UIAlertAction(title: "DJIDashboardViewController.map.mapbox".localized, style: .default, handler: { _ in
                    self.updateMapMapbox()
                })
            ])
        }
        else if let mapViewController = mapViewController as? MapboxMapViewController {
            mapViewController.onMore(sender: sender, actions: [
                UIAlertAction(title: "DJIDashboardViewController.map.microsoft".localized, style: .default, handler: { _ in
                    self.updateMapMicrosoft()
                })
            ])
        }
    }
    
    @objc func onPreflight(sender: Any) {
        let preflightChecklistController = DUXPreflightChecklistController()
        preflightChecklistController.modalPresentationStyle = .formSheet
        present(preflightChecklistController, animated: true, completion: nil)
    }
    
    @objc func onMenu(sender: Any) {
        showOverlay(viewController: DUXCameraSettingsController())
    }
    
    @objc func onExposureSettings(sender: Any) {
        showOverlay(viewController: DUXExposureSettingsController())
    }
    
    @objc func onOffsets(sender: Any) {
        toggleOffsets()
    }
    @objc func onRtkConfiguration() {
        let config = RtkConfiguration()
        config.modalPresentationStyle = .popover
        config.modalTransitionStyle = .coverVertical
        let popover = config.popoverPresentationController!
        popover.sourceView = rtkStatus.view
        present(config, animated: true, completion: nil)
    }
    private func toggleOffsets(visible: Bool? = nil) {
        if let visible = visible {
            if (visible && droneOffsetsViewController1 != nil) || (!visible && droneOffsetsViewController1 == nil) {
                return
            }
        }
        
        if let droneOffsetsViewController = droneOffsetsViewController1 {
            droneOffsetsViewController.view.removeFromSuperview()
            droneOffsetsViewController.removeFromParent()
            self.droneOffsetsViewController1 = nil
        }
        else {
            let droneOffsetsViewController = DroneOffsetsViewController.create(droneSessionManager: self.droneSessionManager, styles: tablet ? [.position] : [.altYaw, .position])
            addChild(droneOffsetsViewController)
            view.addSubview(droneOffsetsViewController.view)
            droneOffsetsViewController.didMove(toParent: self)
            self.droneOffsetsViewController1 = droneOffsetsViewController
        }
        
        if tablet {
            if let droneOffsetsViewController = self.droneOffsetsViewController2 {
                droneOffsetsViewController.view.removeFromSuperview()
                droneOffsetsViewController.removeFromParent()
                self.droneOffsetsViewController2 = nil
            }
            else {
                let droneOffsetsViewController = DroneOffsetsViewController.create(droneSessionManager: self.droneSessionManager, styles: [.altYaw])
                addChild(droneOffsetsViewController)
                view.addSubview(droneOffsetsViewController.view)
                droneOffsetsViewController.didMove(toParent: self)
                self.droneOffsetsViewController2 = droneOffsetsViewController
            }
        }
        
        if let cameraOffsetsViewController = self.cameraOffsetsViewController {
            cameraOffsetsViewController.view.removeFromSuperview()
            cameraOffsetsViewController.removeFromParent()
            self.cameraOffsetsViewController = nil
        }
        else {
            let cameraOffsetsViewController = CameraOffsetsViewController.create(droneSessionManager: self.droneSessionManager)
            addChild(cameraOffsetsViewController)
            view.addSubview(cameraOffsetsViewController.view)
            cameraOffsetsViewController.didMove(toParent: self)
            self.cameraOffsetsViewController = cameraOffsetsViewController
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    private func showOverlay(viewController: UIViewController) {
        overlayViewController = viewController
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.addShadow()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onHideOverlay(sender: Any!) {
        overlayViewController?.removeFromParent()
        overlayViewController?.view.removeFromSuperview()
        overlayViewController = nil
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onHideInterface() {
        interfaceVisible = false
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onShowInterface() {
        interfaceVisible = true
        view.setNeedsUpdateConstraints()
    }

    @objc func onDismiss(sender: Any) {
        delegate?.onDashboardDismissed()
        dismiss(animated: true)
    }
    
    private func apply(userInterfaceSettings: Mission.UserInterfaceSettings?) {
        reticalImageView.image = nil
        if let reticalImageUrl = userInterfaceSettings?.reticalImageUrl {
            reticalImageView.kf.setImage(with: URL(string: reticalImageUrl))
        }
        
        if let droneOffsetsVisible = userInterfaceSettings?.droneOffsetsVisible {
            offsetsButtonEnabled = droneOffsetsVisible
            toggleOffsets(visible: droneOffsetsVisible)
        }
        else {
            offsetsButtonEnabled = false
            toggleOffsets(visible: false)
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    //work-around for this: https://github.com/flutter/flutter/issues/35784
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}

extension DJIDashboardViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {
    }
    
    public func onMissionLoaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = executor
            let missionViewController = MissionViewController.create(droneSessionManager: self.droneSessionManager, delegate: self)
            self.addChild(missionViewController)
            self.view.addSubview(missionViewController.view)
            missionViewController.didMove(toParent: self)
            self.missionViewController = missionViewController
            executor.add(delegate: self)
            self.apply(userInterfaceSettings: executor.userInterfaceSettings)
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = nil
            if let missionViewController = self.missionViewController {
                missionViewController.view.removeFromSuperview()
                missionViewController.removeFromParent()
                self.missionViewController = nil
            }
            executor.remove(delegate: self)
            
            self.apply(userInterfaceSettings: nil)
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
        DispatchQueue.main.async {
            self.funcExecutor = executor
            self.funcExpanded = false
            let funcViewController = FuncViewController.create(droneSessionManager: self.droneSessionManager, delegate: self)
            self.addChild(funcViewController)
            self.view.addSubview(funcViewController.view)
            funcViewController.didMove(toParent: self)
            self.funcViewController = funcViewController
            self.apply(userInterfaceSettings: executor.userInterfaceSettings)
        }
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
        DispatchQueue.main.async {
            self.funcExecutor = nil
            if let funcViewController = self.funcViewController {
                funcViewController.view.removeFromSuperview()
                funcViewController.removeFromParent()
                self.funcViewController = nil
            }
            
            if self.missionExecutor == nil {
                self.apply(userInterfaceSettings: nil)
            }
            else {
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
}

extension DJIDashboardViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        session.add(delegate: self)
        DispatchQueue.main.async {
            if !self.primaryViewToggled {
                self.videoPreviewerPrimary = true
            }
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        session.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension DJIDashboardViewController: DroneSessionDelegate {
    public func onInitialized(session: DroneSession) {
        if let cameraState = session.cameraState(channel: 0), !cameraState.value.isSDCardInserted {
            DronelinkUI.shared.showDialog(title: "DJIDashboardViewController.camera.noSDCard.title".localized, details: "DJIDashboardViewController.camera.noSDCard.details".localized)
        }
    }
    
    public func onLocated(session: DroneSession) {}
    
    public func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    public func onCommandExecuted(session: DroneSession, command: MissionCommand) {}
    
    public func onCommandFinished(session: DroneSession, command: MissionCommand, error: Error?) {}
    
    public func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
}

extension DJIDashboardViewController: MissionExecutorDelegate {
    public func onMissionEstimating(executor: MissionExecutor) {}
    
    public func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {}
    
    public func onMissionEngaging(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
        
    public func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Mission.Message) {
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension DJIDashboardViewController: MissionViewControllerDelegate {
    public func onMissionExpandToggle() {
        updateConstraintsMission()
        view.animateLayout()
    }
}

extension DJIDashboardViewController: FuncViewControllerDelegate {
    public func onFuncExpanded(value: Bool) {
        funcExpanded = value
        updateConstraints()
        view.animateLayout()
    }
}
