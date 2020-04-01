//
//  OZFrameViewController.swift
//  Alamofire
//
//  Created by Igor Ovchinnikov on 19/08/2019.
//

import Foundation
import AVFoundation
import UIKit
import FirebaseMLVision
import DeviceKit

class OZFrameViewController: UIViewController {
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        set {}
        get {
            return .fullScreen
        }
    }
    
    let сThreshold      : CGFloat = OZSDK.thresholdSettings.centerError
    let hThreshold      : CGFloat = OZSDK.thresholdSettings.heightError
    let smileThreshold  : CGFloat = OZSDK.thresholdSettings.smilingProbability
    let eyesThreshold   : CGFloat = OZSDK.thresholdSettings.eyesOpenProbability
    
    let leftThreshold   : CGFloat = OZSDK.thresholdSettings.leftHeadEulerAngleY
    let rightThreshold  : CGFloat = OZSDK.thresholdSettings.rightHeadEulerAngleY
    
    let downThreshold   : CGFloat = (1 - OZSDK.thresholdSettings.downFaceProbability) / OZSDK.thresholdSettings.normalFaceProportion
    let highThreshold   : CGFloat = (1 - OZSDK.thresholdSettings.highFaceProbability) * OZSDK.thresholdSettings.normalFaceProportion
    
    // MARK: - Face detection parameters
    
    var frameView: OZFrameView?
    
    var infoLabel: UILabel?
    var actionButton: UIButton?
    var closeButton: UIButton?
    
    var session: AVCaptureSession?
    
    var videoOutput: AVCaptureVideoDataOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    let videoProportion: CGFloat = 9/16
    let faceProportion: CGFloat = 1.6
    let mlKitScale: CGFloat = 1.2
    
    var captureImageSize = CGSize(
        width:  1280,
        height: 720
    )
    
    lazy var nFaceFrame: CGSize = {
        if view.bounds.height / view.bounds.width < faceProportion {
            let side = view.bounds.height / faceProportion * 0.9
            return CGSize(width: side / faceProportion, height: side)
        }
        else {
            let side = view.bounds.width * 0.9
            return CGSize(width: side, height: side * faceProportion)
        }
    }()
    
    lazy var fFaceFrame: CGSize = {
        if view.bounds.height / view.bounds.width < faceProportion {
            let side = view.bounds.height / faceProportion * 0.6
            return CGSize(width: side / faceProportion, height: side)
        }
        else {
            let side = view.bounds.width * 0.6
            return CGSize(width: side, height: side * faceProportion)
        }
    }()
    
    lazy var vision = Vision.vision()
    
    
    override func viewDidAppear(_ animated: Bool) {
        self.pSessionAndVideoLayer()
        self.pFrameView()
        self.pInfoLabel()
        self.pStartButton()
        self.pCloseButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        self.requestCameraAccess()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        videoOutput?.setSampleBufferDelegate(nil, queue: videoOutputQueue)
    }
    
    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized, .notDetermined, .restricted:()
        case .denied:
            let alert = UIAlertController.alert(title:      OZResources.localized(key: "CameraAccess.Alert.Title"),
                                                message:    OZResources.localized(key: "CameraAccess.Alert.Message"),
                                                okTitle:    OZResources.localized(key: "CameraAccess.Alert.OkTitle"),
                                                okAction: { [weak self] in
                self?.closeAction(sender: nil)
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options:[:], completionHandler: nil)
            }, cancelTitle: OZResources.localized(key: "CameraAccess.Alert.CancelTitle")) { [weak self] in
                self?.closeAction(sender: nil)
            }
            self.present(alert, animated: true, completion: nil)
        @unknown default:()
        }
    }
    
    // MARK: - Prepare views func
    
    private func pStartButton() {
        
    }
    
    func pFrameView() {
        guard let videoPreviewLayer = videoPreviewLayer else { return }
        self.view.layoutSubviews()
    }
    
    func pInfoLabel() {
        let textColor = OZSDK.customization.textColor
        if infoLabel == nil {
            let infoLabel = UILabel(frame: self.view.frame)
            infoLabel.font = UIFont.systemFont(ofSize: 20.0)
            infoLabel.numberOfLines = 0
            infoLabel.textColor = textColor
            // TODO: нужно добавить в конфиги
            infoLabel.shadowColor = UIColor.black
            infoLabel.shadowOffset = CGSize(width: 2.0, height: 2.0)
            infoLabel.textAlignment = .center
            self.view.addSubview(infoLabel)
            self.infoLabel = infoLabel
        }
    }
    
    func pCloseButton() {
        let buttonColor = OZSDK.customization.buttonColor
        let yOffset: CGFloat
        if #available(iOS 11, *) {
            yOffset = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        }
        else {
            yOffset = 0
        }
        let side: CGFloat = 28.0
        
        let closeButton = self.closeButton ?? UIButton(frame: CGRect(x: Device.current.hasRoundedDisplayCorners ? 16.0 : 8.0,
                                                                     y: yOffset + (Device.current.hasRoundedDisplayCorners ? 8.0 : 24.0),
                                                                     width: side,
                                                                     height: side))
        if self.closeButton?.superview == nil {
            if let icon = OZSDK.customization.cancelButtonCustomization.customImage {
                closeButton.setImage(icon, for: UIControl.State.normal)
                closeButton.sizeToFit()
            }
            else {
                closeButton.setImage(OZResources.closeButtonImage, for: UIControl.State.normal)
            }
            closeButton.addTarget(self, action: #selector(closeAction(sender:)), for: .touchUpInside)
            closeButton.setTitleColor(buttonColor, for: .normal)
            closeButton.setTitleColor(buttonColor.withAlphaComponent(0.3), for: .highlighted)
            closeButton.setTitleColor(buttonColor.withAlphaComponent(0.1), for: .disabled)
            
            view.addSubview(closeButton)
            self.closeButton = closeButton
        }
        self.closeButton?.isEnabled = true
    }
    
    @objc func closeAction(sender: UIButton?) {
        self.dismiss(animated: true)
    }
    
    func changeInfo(text: String) {
        DispatchQueue.main.async {
            self.infoLabel?.text = text
        }
    }
    
    private func pSessionAndVideoLayer() {
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSession.Preset.iFrame1280x720
        guard   let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: frontCamera) else { return }
        
        if let session = session, session.canAddInput(input) {
            session.addInput(input)
            videoOutput = AVCaptureVideoDataOutput()
            if let videoOutput = videoOutput, session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer?.videoGravity = .resizeAspect
                videoPreviewLayer?.connection?.videoOrientation = .portrait
                view.layer.addSublayer(videoPreviewLayer!)
                session.startRunning()
            }
        }
        
        let position = CGPoint(x: (view.bounds.width - view.bounds.height * videoProportion) / 2, y: 0)
        videoPreviewLayer?.frame = CGRect(origin: position,
                                          size: CGSize(width: view.bounds.height * videoProportion,
                                                       height: view.bounds.height))
    }
    
    // MARK: - Vision configuration
    
    let videoOutputQueue = DispatchQueue(label: "liveness.videooutput.queue")
    
    lazy var faceDetectorOptions: VisionFaceDetectorOptions = {
        let options = VisionFaceDetectorOptions()
        options.modeType = .fast
        options.landmarkType = .all
        options.classificationType = .all
        return options
    }()
    
    lazy var metadata: VisionImageMetadata = {
        let metadata = VisionImageMetadata()
        metadata.orientation = .leftTop
        return metadata
    }()
    
    // MARK: Face detection
    
    var blockDetection = false
    
    var mlKitFPS : CGFloat = 0
    
    func detectFaces(in buffer: CMSampleBuffer) {
        guard !self.blockDetection else { return }
        self.blockDetection = true
        let date = Date()
        
        let visionImage = VisionImage(buffer: buffer)
        visionImage.metadata = self.metadata
        let faceDetector = vision.faceDetector(options: faceDetectorOptions)
        faceDetector.detect(in: visionImage) { [weak self] faces, error in
            self?.process(faces: faces ?? []) { [weak self] in
                self?.blockDetection = false
                self?.mlKitFPS = 1/CGFloat(-date.timeIntervalSinceNow)
            }
        }
    }
    
    func process(faces: [VisionFace], completion: @escaping (() -> Void)) {
        
    }
}

extension OZFrameViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        self.detectFaces(in: sampleBuffer)
    }
}

// MARK: - Orientation (fix) delegate

extension OZFrameViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
}
