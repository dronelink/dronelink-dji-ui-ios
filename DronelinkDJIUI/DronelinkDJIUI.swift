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
import DJIWidget

extension DronelinkDJIUI {
    public static let shared = DronelinkDJIUI()
    public static let bundle = Bundle(for: DronelinkDJIUI.self)
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
        (current as? ViewControllerWidget)?.viewController is DUXPreflightChecklistController ? current : DUXPreflightChecklistController().createWidget()
    }

    open override func videoFeedWidgetEnabled(channel: UInt?) -> Bool {
        if session == nil {
            return false
        }

        if channel ?? 0 == 0 {
            return true
        }

        return (session as? DJIDroneSession)?.adapter.drone.multipleVideoFeedsEnabled ?? false
    }

    open override func createVideoFeedWidget(channel: UInt? = nil, current: Widget? = nil) -> Widget? {
        if session == nil {
            return nil
        }
        
        var channelResolved = channel ?? 0
        var multipleVideoFeedsEnabled = (session as? DJIDroneSession)?.adapter.drone.multipleVideoFeedsEnabled ?? false
        if !multipleVideoFeedsEnabled && channelResolved > 0 {
            return nil
        }
        
        var defaultVideoPreviewer = multipleVideoFeedsEnabled
        if !defaultVideoPreviewer {
            switch session?.model ?? "" {
            //DUXFPVViewController doesn not seem to work for these drones :(
            case DJIAircraftModelNameDJIMini2,
                DJIAircraftModelNameDJIAir2S,
                "":
                defaultVideoPreviewer = true
                
            default:
                break
            }
        }

        if defaultVideoPreviewer {
            if let videoPreviewerViewController = current as? VideoPreviewerViewController,
               videoPreviewerViewController.channel == channelResolved {
                return current
            }

            return VideoPreviewerViewController.create(channel: channelResolved)
        }

        if channelResolved == 0 {
            if let current = current as? ViewControllerWidget, current.viewController is DUXFPVViewController {
                return current
            }

            //FIXME seems to have issues displaying the video feed if using after VideoPreviewerViewController...
            let fpvViewController = DUXFPVViewController()
            let widget = fpvViewController.createWidget()
            fpvViewController.isHUDInteractionEnabled = true
            fpvViewController.isRadarWidgetVisible = true
            fpvViewController.fpvView?.showCameraDisplayName = false

            return widget
        }

//        if let adapter = session?.drone as? DJIDroneAdapter, adapter.drone.videoFeeder?.secondaryVideoFeed != nil {
//            if current?.view.subviews.first is DUXPIPVideoFeedWidget {
//                return current
//            }
//
//            return DUXPIPVideoFeedWidget().createWidget()
//        }

        return nil
    }

    open override func createBatteryWidget(current: Widget? = nil) -> Widget? {
        session == nil ? nil : current?.view.subviews.first is DUXBatteryWidget ? current : DUXBatteryWidget().createWidget(shadow: true)
    }

    open override func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXRemainingFlightTimeWidget ? current : DUXRemainingFlightTimeWidget().createWidget()
    }

    open override func createVisionWidget(current: Widget? = nil) -> Widget? {
        current?.view.subviews.first is DUXVisionWidget ? current : DUXVisionWidget().createWidget(shadow: true)
    }

    open override func cameraMenuWidgetEnabled(channel: UInt? = nil) -> Bool { true }

    open override func createCameraMenuWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = (current as? ChannelViewControllerWidget)?.viewController is DUXCameraSettingsController ? current : DUXCameraSettingsController().createWidget(channel: channel)
        widget?.channel = channel
        ((widget as? ChannelViewControllerWidget)?.viewController as? DUXCameraSettingsController)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }
    
    open override func createCameraVideoStreamSourceWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let cameraModel = session?.drone.camera(channel: channel ?? session?.drone.cameraChannel(videoFeedChannel: nil) ?? 0)?.model ?? ""
        switch cameraModel {
        case DJICameraDisplayNameZenmuseH20, DJICameraDisplayNameZenmuseH20T:
            if let widget = channelWidget(channel: channel, widget: (current as? CameraVideoStreamSourceWidget) ?? CameraVideoStreamSourceWidget()) as? CameraVideoStreamSourceWidget {
                if cameraModel == DJICameraDisplayNameZenmuseH20 {
                    widget.sources = [.wide, .zoom]
                }
                else {
                    widget.sources = [.wide, .zoom, .thermal]
                }
                return widget
            }
        default:
            break
        }
        
        return nil
    }

    open override func createCameraStorageWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = current?.view.subviews.first is DUXCameraConfigStorageWidget ? current : DUXCameraConfigStorageWidget().createWidget(channel: channel)
        widget?.channel = channel
        (widget?.view.subviews.first as? DUXCameraConfigStorageWidget)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }

    open override func createCameraAutoExposureWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = current?.view.subviews.first is DUXAutoExposureSwitchWidget ? current : DUXAutoExposureSwitchWidget().createWidget(channel: channel)
        widget?.channel = channel
        (widget?.view.subviews.first as? DUXAutoExposureSwitchWidget)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }

    open override func createCameraExposureFocusWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = current?.view.subviews.first is DUXExposureFocusSwitchWidget ? current : DUXExposureFocusSwitchWidget().createWidget(channel: channel)
        widget?.channel = channel
        (widget?.view.subviews.first as? DUXExposureFocusSwitchWidget)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }

    open override func createCameraFocusModeWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = current?.view.subviews.first is DUXFocusModeWidget ? current : DUXFocusModeWidget().createWidget(channel: channel)
        widget?.channel = channel
        (widget?.view.subviews.first as? DUXFocusModeWidget)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }

    open override func cameraExposureMenuWidgetEnabled(channel: UInt? = nil) -> Bool { true }

    open override func createCameraExposureMenuWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? {
        let widget = (current as? ChannelViewControllerWidget)?.viewController is DUXExposureSettingsController ? current : DUXExposureSettingsController().createWidget(channel: channel)
        widget?.channel = channel
        ((widget as? ChannelViewControllerWidget)?.viewController as? DUXExposureSettingsController)?.preferredCameraIndex = widget?.channelResolved ?? 0
        return widget
    }

    open override func createCompassWidget(current: Widget?) -> Widget? {
        current?.view.subviews.first is DUXCompassWidget ? current : DUXCompassWidget().createWidget()
    }

    open override func createRTKStatusWidget(current: Widget? = nil) -> Widget? {
        if (current is RTKStatusWidget) {
            return current
        }

        let widget = RTKStatusWidget()
        widget.createManager = {(session) in
            if let djiSession = session as? DJIDroneSession {
                return DJIRTKManager(djiSession.adapter.drone)
            }
            return nil
        }
        return widget
    }

    open override func createRTKMenuWidget(current: Widget? = nil) -> Widget? {
        RTKSettingsWidget()
    }
}

class VideoPreviewerViewController: DelegateWidget, ConfigurableWidget {
    static func create(channel: UInt) -> VideoPreviewerViewController? {
        let viewController = VideoPreviewerViewController()
        viewController.channel = channel
        viewController.feed = DJISDKManager.product()?.videoFeeder?.feed(channel: channel)
        return viewController
    }
    
    let detailsLabel = UILabel()
    let feedView = UIView()
    var channel: UInt?
    var feed: DJIVideoFeed?
    var videoPreviewer: DJIVideoPreviewer?
    var adapter: VideoPreviewerAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let feed = feed, let videoPreviewer = DJIVideoPreviewer() else {
            return
        }
        
        self.videoPreviewer = videoPreviewer
        videoPreviewer.type = .autoAdapt
        videoPreviewer.start()
        
        adapter = VideoPreviewerAdapter(videoPreviewer: videoPreviewer, with: feed)
        adapter?.start()
        adapter?.setupFrameControlHandler()
        
        if (session as? DJIDroneSession)?.adapter.drone.multipleVideoFeedsEnabled ?? false {
            detailsLabel.textAlignment = .center
            detailsLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            detailsLabel.backgroundColor = DronelinkUI.Constants.overlayColor
            view.addSubview(detailsLabel)
            detailsLabel.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(30)
            }
            
            updateDetails()
        }
        
        if channel == 0 {
            //must do this for the M300 video feed! https://github.com/dji-sdk/Mobile-SDK-iOS/issues/407
            try? session?.add(command: Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0 : .fpvCamera, 1: .leftCamera]))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoPreviewer?.setView(view)
        videoPreviewer?.reset()
    }
    
    deinit {
        adapter?.stop()
        videoPreviewer?.unSetView()
        videoPreviewer?.close()
    }
    
    var configurationActions: [UIAlertAction] {
        var actions: [UIAlertAction] = []
        
        let configurations: [Kernel.OcuSyncVideoFeedSourcesDroneCommand] = [
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .fpvCamera, 1: .leftCamera]),
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .fpvCamera, 1: .rightCamera]),
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .fpvCamera, 1: .topCamera]),
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .leftCamera, 1: .rightCamera]),
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .leftCamera, 1: .topCamera]),
            Kernel.OcuSyncVideoFeedSourcesDroneCommand(ocuSyncVideoFeedSources: [0: .rightCamera, 1: .topCamera]),
        ]
        
        configurations.forEach { [weak self] configuration in
            actions.append(UIAlertAction(title: "1: \(configuration.djiValue(channel: 0).message.details ?? "") 2: \(configuration.djiValue(channel: 1).message.details ?? "")", style: .default, handler: { _ in
                try? self?.session?.add(command: configuration)
            }))
        }
        
        return actions
    }
    
    open override func onVideoFeedSourceUpdated(session: DroneSession, channel: UInt?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateDetails()
        }
    }
    
    func updateDetails() {
        guard let feed = feed else {
            return
        }
        
        var details: [String] = []
        if feed.physicalSource != .unknown {
            if let channel = channel, let cameraChannel = session?.drone.cameraChannel(videoFeedChannel: channel), let model = session?.drone.camera(channel: cameraChannel)?.model {
                details.append(model)
            }
            
            if let source = feed.physicalSource.message.details {
                details.append(source)
            }
        }
        
        details.append("\((channel ?? 0) + 1)")
        
        detailsLabel.text = details.joined(separator: " | ")
    }
}
