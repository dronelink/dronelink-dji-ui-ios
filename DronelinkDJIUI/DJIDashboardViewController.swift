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

public protocol DJIDashboardViewControllerDelegate {
    func onDashboardDismissed()
}

public class DJIDashboardViewController: UIViewController {
    public static func create(droneSessionManager: DJIDroneSessionManager, delegate: DJIDashboardViewControllerDelegate? = nil) -> DJIDashboardViewController {
        let dashboardViewController = DJIDashboardViewController()
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
    private var mapViewController: MapViewController!
    private let primaryViewToggleButton = UIButton(type: .custom)
    private let dismissButton = UIButton(type: .custom)
    private let videoPreviewerViewController = DUXFPVViewController()
    private var videoPreviewerView = UIView()
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
    
    private var telemetryViewController: TelemetryViewController?
    private var droneOffsetsViewController: DroneOffsetsViewController?
    private var missionViewController: MissionViewController?
    private var missionExpanded = false
    private var funcViewController: FuncViewController?
    private var videoPreviewerPrimary = true
    private let defaultPadding = 10
    private var primaryView: UIView { return videoPreviewerPrimary || portrait ? videoPreviewerView : mapViewController.view }
    private var secondaryView: UIView { return primaryView == videoPreviewerView ? mapViewController.view : videoPreviewerView }
    private var portrait: Bool { return UIScreen.main.bounds.width < UIScreen.main.bounds.height }
    private var tablet: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    private var statusWidgetHeight: CGFloat { return tablet ? 50 : 40 }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.backgroundColor = UIColor.black
        
        hideOverlayButton.addTarget(self, action: #selector(onHideOverlay(sender:)), for: .touchUpInside)
        view.addSubview(hideOverlayButton)
        
        addChild(videoPreviewerViewController)
        videoPreviewerViewController.didMove(toParent: self)
            
        videoPreviewerView = videoPreviewerViewController.view
        videoPreviewerView.addShadow()
        videoPreviewerView.backgroundColor = UIColor(displayP3Red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        view.addSubview(videoPreviewerView)
        
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
        
        let mapViewController = MapViewController.create(droneSessionManager: self.droneSessionManager)
        self.mapViewController = mapViewController
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
        
        primaryViewToggleButton.tintColor = UIColor.white
        primaryViewToggleButton.setImage(DronelinkDJIUI.loadImage(named: "vector-arrange-below"), for: .normal)
        primaryViewToggleButton.addTarget(self, action: #selector(onPrimaryViewToggle(sender:)), for: .touchUpInside)
        view.addSubview(primaryViewToggleButton)
        
        let telemetryViewController = TelemetryViewController.create(droneSessionManager: self.droneSessionManager)
        addChild(telemetryViewController)
        view.addSubview(telemetryViewController.view)
        telemetryViewController.didMove(toParent: self)
        self.telemetryViewController = telemetryViewController
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
        view.sendSubviewToBack(primaryView)
        view.bringSubviewToFront(secondaryView)
        view.bringSubviewToFront(primaryViewToggleButton)
        view.bringSubviewToFront(compassWidget)
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
                make.width.equalTo(view.snp.width).multipliedBy(tablet ? 0.4 : 0.28)
                make.height.equalTo(secondaryView.snp.width).multipliedBy(0.5)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            }
        }
        
        primaryViewToggleButton.isHidden = portrait
        primaryViewToggleButton.snp.remakeConstraints { make in
            make.left.equalTo(secondaryView.snp.left).offset(defaultPadding)
            make.top.equalTo(secondaryView.snp.top).offset(defaultPadding)
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
            make.bottom.equalTo(offsetsButton.snp.bottom).offset(15)
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
        
        offsetsButton.tintColor = droneOffsetsViewController == nil ? UIColor.white : MDCPalette.pink.accent400
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
            make.height.equalTo(secondaryView.snp.height).multipliedBy(0.65)
            make.right.equalTo(captureBackgroundView.snp.left).offset(-defaultPadding * 2)
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
        
        if let droneOffsetsViewController = droneOffsetsViewController {
            view.bringSubviewToFront(droneOffsetsViewController.view)
            droneOffsetsViewController.view.snp.remakeConstraints { make in
                make.height.equalTo(240)
                make.width.equalTo(200)
                if portrait {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                    make.top.equalTo(secondaryView.snp.top).offset(defaultPadding)
                }
                else {
                    make.right.equalTo(captureBackgroundView.snp.left).offset(-defaultPadding)
                    make.top.equalTo(captureBackgroundView.snp.top)
                }
            }
        }
        
        updateConstraintsMission()
        updateConstraintsFunc()
        updateConstraintsOverlay()
    }
    
    func updateConstraintsMission() {
        if let missionViewController = missionViewController {
            view.bringSubviewToFront(missionViewController.view)
            missionViewController.view.snp.remakeConstraints { make in
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalToSuperview().multipliedBy(0.45)
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
                    make.right.equalTo(secondaryView.snp.right)
                }
                else {
                    make.width.equalToSuperview().multipliedBy(0.4)
                }
                if (missionExpanded) {
                    make.bottom.equalTo(secondaryView.snp.top).offset(-Double(defaultPadding) * 1.5)
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
                make.height.equalTo(200)
                
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalTo(350)
                    return
                }
                
                if (portrait) {
                    make.right.equalToSuperview()
                    make.left.equalToSuperview()
                    make.bottom.equalToSuperview()
                    return
                }
                
                make.top.equalTo(topBarBackgroundView.snp.bottom).offset(defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalTo(350)
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
        videoPreviewerPrimary = !videoPreviewerPrimary
        updateConstraints()
        view.animateLayout()
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
        if let droneOffsetsViewController = self.droneOffsetsViewController {
            droneOffsetsViewController.view.removeFromSuperview()
            droneOffsetsViewController.removeFromParent()
            self.droneOffsetsViewController = nil
        }
        else {
            let droneOffsetsViewController = DroneOffsetsViewController.create(droneSessionManager: self.droneSessionManager)
            addChild(droneOffsetsViewController)
            view.addSubview(droneOffsetsViewController.view)
            droneOffsetsViewController.didMove(toParent: self)
            self.droneOffsetsViewController = droneOffsetsViewController
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

    @objc func onDismiss(sender: Any) {
        delegate?.onDashboardDismissed()
        dismiss(animated: true)
    }
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
            self.view.setNeedsUpdateConstraints()
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
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
        DispatchQueue.main.async {
            self.funcExecutor = executor
            let funcViewController = FuncViewController.create(droneSessionManager: self.droneSessionManager)
            self.addChild(funcViewController)
            self.view.addSubview(funcViewController.view)
            funcViewController.didMove(toParent: self)
            self.funcViewController = funcViewController
            self.view.setNeedsUpdateConstraints()
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
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension DJIDashboardViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        DispatchQueue.main.async {
            self.session = session
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onClosed(session: DroneSession) {
        DispatchQueue.main.async {
            self.session = nil
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension DJIDashboardViewController: MissionExecutorDelegate {
    public func onMissionEstimated(executor: MissionExecutor, duration: TimeInterval) {}
    
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
    public func onExpandToggle() {
        missionExpanded = !missionExpanded
        updateConstraintsMission()
        view.animateLayout()
    }
}
