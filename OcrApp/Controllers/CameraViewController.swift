//
//  CameraViewController.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 30/01/2025.
//

import UIKit
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

public enum ScanState {
    case notStarted,started,stop
}

class CameraViewController: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var crossButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    
    var imageView = UIImageView()
    var requests = [VNRequest]()
    var session:AVCaptureSession!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var borderBoxView: UIView!
    var detectedBoundingBoxes: [CGRect] = []
    var detectedGroups: [TextGroup] = []
    var frameCount = 0
    var searchingString = "" {
        didSet {
            let searchComponents = searchingString.components(separatedBy: ",")
            street = (searchComponents.count > 0 ? searchComponents.first?.lowercased() : "") ?? ""
            postal = (searchComponents.count > 1 ? searchComponents.last : "") ?? ""
        }
    }
    var detectedParagraphText: String = ""
    var imageAndTextReceived: ((UIImage?,String?)->Void)?
    var imageAndNotMatchTextReceived: ((UIImage?,[String])->Void)?
    var capturedImage: UIImage?
    var overlayView: UIView?
    let photoOutput = AVCapturePhotoOutput()
    var sampleBuffer: CMSampleBuffer?
    var pixelBuffer: CVPixelBuffer?
    var detectedTextLayer = CALayer()
    var firstTimeShown = false
    private var street = ""
    private var postal = ""
    private var foundMatchedGroup = false
    
    private var scanState = ScanState.notStarted
    var secondsRemaining = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOrientation(.landscape)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setOrientation(.portrait)
        requests.removeAll()
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard firstTimeShown == false else {return}
        firstTimeShown = true
        reader(to: view)
        setupBorderBox()
        view.bringSubviewToFront(crossButton)
        view.bringSubviewToFront(scanButton)
        imageView.frame = view.bounds
        imageView.backgroundColor = UIColor.clear
        view.addSubview(imageView)
//        scanState = scanState == .notStarted ? ScanState.started : ScanState.stop
//        pauseStopTextDetection(start: scanState == .started)
//        timerStart()
    }
    
    func timerStart() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {return}
            self.secondsRemaining -= 1
            guard self.secondsRemaining > 0 else {
                timer.invalidate()
                if foundMatchedGroup == false {
                    showRescanAlertWithOk { ok in
                        self.secondsRemaining = 10
                        self.timerStart()
                        self.detectedGroups.removeAll()
                    }
                }
                return
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else { return }
        
        let touchLocationInMainView = touch.location(in: self.view)
        
        let tappedGroup = detectedGroups.first(where: {$0.rect.contains(touchLocationInMainView)})
        guard tappedGroup != nil else {return}
        let mappedGroupString = tappedGroup?.textElements.map{$0.text}.joined(separator: "\n") ?? ""
        let isFoundMatched = mappedGroupString.contains(street) || mappedGroupString.contains(postal)
        if isFoundMatched {
            guard let buffer = sampleBuffer,let capturedImage = captureImage(from: buffer) else {return}
            let correctImage = ensureLandscapeOrientation(image: capturedImage)
            self.imageAndTextReceived?(correctImage, mappedGroupString)
        }
        
        
        // Group the text elements by position
//        let mappedArray = detectedGroups.map { $0.textElements.map { $0.text }.joined(separator: "\n") }
//        let foundMatchedGroup = mappedArray.first(where: {$0.contains(street) || $0.contains(postal)})
        
        
//        for textGroup in self.detectedGroups {
//            if textGroup.rect.contains(touchLocationInMainView) {
//                print("touch detected in MainView on textGroup starting with: \(textGroup.textElements.first?.text ?? "")")
//                let storybd = UIStoryboard(name: "Main", bundle: nil)
//                guard let vc = storybd.instantiateViewController(withIdentifier:
//                                                                    String(describing: AddressListVC.self)) as? AddressListVC else { return }
//                if let foundMatchedGroup = foundMatchedGroup {
//                    
//                    vc.sectionArray = ["Matched Address", "Selected Address"]
//                    vc.matchedAddress = foundMatchedGroup
//                    vc.selectedAddress = self.joinTextOfGroups(textGroups: [textGroup])
//                    
//                } else {
//                    
//                    vc.sectionArray = ["Selected Address"]
//                    vc.selectedAddress = self.joinTextOfGroups(textGroups: [textGroup])
//                }
//                
////                self.navigationController?.pushViewController(vc, animated: true)
////                vc.delegate = self
////                vc.modalPresentationStyle = .fullScreen
////                self.present(vc, animated: true) {
//////                    self?.setOrientation(.portrait)
////                }
//                if let buffer = sampleBuffer,let capturedImage = captureImage(from: buffer) {
//                    let correctImage = ensureLandscapeOrientation(image: capturedImage)
//                    self.capturedImage = correctImage
//                    self.imageAndTextReceived?(capturedImage, self.joinTextOfGroups(textGroups: [textGroup]))
//                }
//                
//            }
//        }
    }
    
    deinit {
        print("deinit")
    }
    
    // Function to join text elements from the array of TextGroup
    func joinTextOfGroups(textGroups: [TextGroup]) -> String {
        // Flatten all text elements and join by \n
        return textGroups
            .flatMap { $0.textElements } // Flatten the array of TextElements
            .map { $0.text }             // Extract the text from each TextElementWithRect
            .joined(separator: "\n")      // Join all text strings by a newline
    }
    
    func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            // For iOS 16+
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            }
        } else {
            // For iOS 15 and below
            DispatchQueue.main.async {
                if orientation == .landscape {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
            }
        }
    }


    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        removeAllSession()
        self.dismiss(animated: true)
    }
    
    func removeAllSession() {
        session?.stopRunning()
        session?.inputs.forEach { session?.removeInput($0) }
        session?.outputs.forEach { session?.removeOutput($0) }
        session = nil
        
        previewLayer?.removeFromSuperlayer()
        requests.removeAll()
        scanButton.setTitle("Start Scan", for: .normal)
        overlayView?.removeFromSuperview()
    }
    
    func setupBorderBox() {
        // Define the size and position of the square
        let squareSize = CGSize(width: view.frame.size.width * 0.6, height: view.frame.size.height * 0.7)
        let squareOrigin = CGPoint(x: view.bounds.midX - squareSize.width / 2,
                                   y: view.bounds.midY - squareSize.height / 1.5) // Fix y positioning
        let squareRect = CGRect(origin: squareOrigin, size: squareSize)
        
        // Create a semi-transparent overlay
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.clear
        view.addSubview(overlayView)
        self.overlayView = overlayView
        // Create a path for the cutout
        let path = UIBezierPath(rect: overlayView.bounds)
        let squarePath = UIBezierPath(roundedRect: squareRect, cornerRadius: 5)
        path.append(squarePath)
        path.usesEvenOddFillRule = true
        
        // Create a mask layer
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        // Add the border box
        borderBoxView = UIView(frame: squareRect)
        borderBoxView.layer.borderWidth = 4
        borderBoxView.layer.borderColor = UIColor.white.cgColor
        borderBoxView.layer.cornerRadius = 25
        borderBoxView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(borderBoxView)
        let verticalShift = (squareSize.height / 2) - (squareSize.height / 1.8)
        // Use Auto Layout for centering
        NSLayoutConstraint.activate([
            borderBoxView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            borderBoxView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: verticalShift),
            borderBoxView.widthAnchor.constraint(equalToConstant: squareSize.width),
            borderBoxView.heightAnchor.constraint(equalToConstant: squareSize.height)
        ])
//        if let image = UIImage(named: "rectangle") {
//            let imageView = UIImageView(image: image)
//            borderBoxView.addSubview(imageView)
//        }
    }
    
    func addCornerEdges(to view: UIView, length: CGFloat, lineWidth: CGFloat, color: UIColor) {
        let edgeLayer = CAShapeLayer()
        let path = UIBezierPath()

        let w = view.bounds.width
        let h = view.bounds.height

        // Top Left
        path.move(to: CGPoint(x: 0, y: length))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: length, y: 0))

        // Top Right
        path.move(to: CGPoint(x: w - length, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: length))

        // Bottom Right
        path.move(to: CGPoint(x: w, y: h - length))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w - length, y: h))

        // Bottom Left
        path.move(to: CGPoint(x: length, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - length))

        edgeLayer.path = path.cgPath
        edgeLayer.strokeColor = color.cgColor
        edgeLayer.lineWidth = lineWidth
        edgeLayer.fillColor = UIColor.clear.cgColor
        edgeLayer.lineCap = .round

        view.layer.addSublayer(edgeLayer)
    }

    
    func reader(to view:UIView) {
        session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

        do {
            try device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Camera input error: \(error.localizedDescription)")
        }
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.The-I-OS-Tests"))

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        photoOutput.isHighResolutionCaptureEnabled = true

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .landscapeRight  // Adjust based on your landscape orientation

        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }
        view.layer.addSublayer(previewLayer)

        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    @IBAction func startTextDetection(_ sender: UIButton) {
//        guard sender.titleLabel?.text == "Start Scan"  else {
//            sender.setTitle("Start Scan", for: .normal)
//            self.imageAndNotMatchTextReceived = nil
//            removeAllSession()
//            self.dismiss(animated: true)
//            return
//        }
//        sender.setTitle("Stop Scan", for: .normal)
//        let textRequest = VNRecognizeTextRequest {[weak self] request, error in
//            self?.detectTextHandler(request: request, error: error)
//        }
        scanState = .started
        pauseStopTextDetection(start: scanState == .started)
//        textRequest.recognitionLevel = .accurate
//            textRequest.usesLanguageCorrection = true
//            requests = [textRequest]
    }
    
    func pauseStopTextDetection(start: Bool,sender: UIButton? = nil) {
        guard start  else {
//            sender.setTitle("Start Scan", for: .normal)
            self.imageAndNotMatchTextReceived = nil
            removeAllSession()
            self.dismiss(animated: true)
            return
        }
        
        guard let buffer = sampleBuffer,let capturedImage = captureImage(from: buffer) else {
            return
            }
        
        let correctImage = ensureLandscapeOrientation(image: capturedImage)
        LoadIndicator.shared.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Task {
                
                let text = await self.recognizeTextInImage(image: correctImage)
                self.openImageViewerVC(image: correctImage, extractedText: text)
                LoadIndicator.shared.stop()
            }
        }
//        sender.setTitle("Stop Scan", for: .normal)
//        let textRequest = VNRecognizeTextRequest {[weak self] request, error in
//            self?.detectTextHandler2(request: request, error: error, pixelBuffer: pixelBuffer!)
//        }
//        textRequest.recognitionLevel = .accurate
//            textRequest.usesLanguageCorrection = true
//            requests = [textRequest]
//        guard let pixelBuffer = pixelBuffer else {
//                print("No frame available")
//                return
//            }
//
//            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
//            let request = VNRecognizeTextRequest { [weak self] request, error in
//                self?.detectTextHandler2(request: request, error: error, pixelBuffer: pixelBuffer)
//            }
//            
//            request.recognitionLevel = .accurate
//            request.usesLanguageCorrection = true
//
//            DispatchQueue.global(qos: .userInitiated).async {
//                do {
//                    try requestHandler.perform([request])
//                } catch {
//                    print("Error performing text recognition: \(error)")
//                }
//            }
    }
    
    func openImageViewerVC(image: UIImage,extractedText: String) {
        let vc = self.storyboard?.instantiateViewController(identifier: ImageViewerVC.className) as! ImageViewerVC
        vc.image = image
        vc.completion = {(retake,confirm) in
            if retake {
                
            } else if confirm {
                self.imageAndTextReceived?(image, extractedText)
            }
        }
        self.present(vc, animated: true)
    }
    
    func ensureLandscapeOrientation(image: UIImage) -> UIImage {
        let orientation = image.imageOrientation

        // If image is already in landscape, return as is
        if orientation == .up || orientation == .upMirrored {
            return image
        }

        var rotationAngle: CGFloat = 0

        switch orientation {
        case .right, .rightMirrored:
            rotationAngle = -.pi / 2  // Rotate counterclockwise
        case .left, .leftMirrored:
            rotationAngle = .pi / 2   // Rotate clockwise
        case .down, .downMirrored:
            rotationAngle = .pi       // Rotate upside down
        default:
            return image
        }

        // Apply rotation using Core Graphics
        UIGraphicsBeginImageContext(CGSize(width: image.size.height, height: image.size.width))
        guard let context = UIGraphicsGetCurrentContext() else { return image }

        // Move and rotate context
        context.translateBy(x: image.size.height / 2, y: image.size.width / 2)
        context.rotate(by: rotationAngle)

        // Draw the image in new orientation
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage ?? image
    }

    
//    func detectTextHandler(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
//
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.removePreviousBoundingBoxes()
//            self.detectedBoundingBoxes.removeAll()
//
//            var extractedText = ""
//
//            for observation in observations {
//                guard let topCandidate = observation.topCandidates(1).first else { continue }
//                let recognizedText = topCandidate.string
//                let convertedRect = self.convertBoundingBox(observation.boundingBox)
//
//                // Check if the bounding box intersects with the borderBoxView
//                if self.borderBoxView.frame.contains(convertedRect.origin) ||
//                   self.borderBoxView.frame.intersects(convertedRect) {
//                    extractedText += extractedText.isEmpty ? recognizedText : "\n\(recognizedText)"
//
//                }
//            }
//
//            // Handle the extracted text
//            if !extractedText.isEmpty {
//                print("Extracted Text: \(extractedText)")
//                self.detectedParagraphText = extractedText
////                if let capturedImage = self.captureImage() {
////                    self.imageAndTextReceived?(capturedImage, extractedText)
////                }
////                self.removeAllSession() // Stop scanning
//            } else {
//                print("No text found inside the border box.")
//            }
//        }
//    }
    
    

//    func detectTextHandler2(request: VNRequest, error: Error?, pixelBuffer: CVPixelBuffer) {
//
//        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
//
//            DispatchQueue.main.async {
//                self.detectedTextLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // Clear previous layers
//
//                var textElements: [TextElementWithRect] = []
//
//                for observation in observations {
//                    if let bestCandidate = observation.topCandidates(1).first {
//                        let boundingBox = observation.boundingBox
//                        
//                        let imageSize = CGSize(
//                            width: CVPixelBufferGetWidth(self.pixelBuffer!),
//                            height: CVPixelBufferGetHeight(self.pixelBuffer!)
//                        )
//                        var rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
//                        rect.origin.y = imageSize.height - rect.origin.y - rect.height
//                        // Calculate the x and y coordinates of the text element
//                        let x = Int(rect.origin.x)
//                        let y = Int(rect.origin.y)
//                        // Convert coordinates to match previewLayer
//                        if let previewLayer = self.previewLayer {
//                            let viewSize = previewLayer.bounds.size // Get the actual preview size
//                            let convertedRect = self.convertBoundingBoxForRect(boundingBox, imageSize: imageSize, viewSize: viewSize)
//                            // Append to text elements
//                            textElements.append(TextElementWithRect(text: bestCandidate.string, rect: convertedRect, x: x, y: y))
//                            self.drawBoundingBox(for: textElements.last?.rect ?? CGRect())
//                        }
//                    }
//                }
//                
//                // Group detected text elements
////                let groupedText = self.groupTextByPositionWithRect(textElements: textElements, yThreshold: 30, xThreshold: 10)
//
//                // Draw rectangles around grouped text
////                for group in groupedText {
////                    let mergedRect = self.mergeBoundingRects(group.map { $0.rect })
////                    self.drawBoundingBox(rect: mergedRect)
////                }
//            }
//        }
    
    func convertBoundingBoxForRect(_ boundingBox: CGRect, imageSize: CGSize, viewSize: CGSize) -> CGRect {
        var rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))

        // ✅ Flip Y-axis to match iOS top-left coordinate system
        rect.origin.y = imageSize.height - rect.origin.y - rect.height

        // ✅ Scale bounding box to match the screen size (previewLayer size)
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height

        let scaledRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )

        return scaledRect
    }


    func mergeBoundingRects(_ rects: [CGRect]) -> CGRect {
            guard let first = rects.first else { return .zero }
            return rects.dropFirst().reduce(first) { $0.union($1) }
        }
    
    func mergeRects(rects: [CGRect]) -> CGRect {
        // Ensure there's at least one rectangle
        guard !rects.isEmpty else {
            return CGRect.zero
        }
        
        // Find the minimum x, y, and the maximum width
        let minX = rects.min { $0.origin.x < $1.origin.x }?.origin.x ?? 0
        let minY = rects.min { $0.origin.y < $1.origin.y }?.origin.y ?? 0
        let maxWidth = rects.max { $0.width < $1.width }?.width ?? 0
        
        // Calculate the total height by summing up the heights of all rects
        let totalHeight = rects.reduce(0) { $0 + $1.height }
        
        // Return the merged CGRect
        return CGRect(x: minX, y: minY, width: maxWidth, height: totalHeight)
    }
    
    func drawBoundingBox(rect: CGRect) {
        DispatchQueue.main.async {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = UIBezierPath(rect: rect).cgPath
            shapeLayer.strokeColor = UIColor.red.cgColor
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 2

            self.detectedTextLayer.addSublayer(shapeLayer)
        }
    }
    
    func convertBoundingBoxForRect(_ boundingBox: CGRect) -> CGRect {
        let viewWidth = view.frame.width
            let viewHeight = view.frame.height

            // Convert bounding box from normalized Vision coordinates to screen coordinates
            let x = boundingBox.origin.x * viewWidth
            let width = boundingBox.width * viewWidth
            let height = boundingBox.height * viewHeight

            // Adjust Y-coordinate to follow standard coordinate system (top-left origin)
            let y = (1.0 - boundingBox.origin.y) * viewHeight - height

            return CGRect(x: x, y: y, width: width, height: height)
    }

    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.removePreviousBoundingBoxes()
            self.detectedBoundingBoxes.removeAll()

            var previousRect: CGRect?
            var textBlocks: [String] = []
            var currentBlock = ""
            var paragraphBoundingBox: CGRect?
            var paragraphText = ""
            var previousBox: CGRect?
            var previousText: String?
            let addressRegex = "\\d{1,5}\\s\\w+(\\s\\w+)*,?\\s[A-Za-z]+" // Example: "123 Main Street, NY"
            var textInsideRectangle = ""
            let sortedObservations = observations.sorted {
                        $0.boundingBox.minY > $1.boundingBox.minY // Higher on the screen first
                    }
            let addressPredicate = NSPredicate(format: "SELF MATCHES %@", addressRegex)
            for observation in sortedObservations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                let recognizedText = topCandidate.string

                let convertedRect = self.convertBoundingBox(observation.boundingBox)

                // 🔥 Check if text is inside the border box
                if let previous = previousRect {
                    let verticalGap = convertedRect.minY - previous.maxY
                    if verticalGap > 10 { // Adjust gap threshold as needed
                        if !currentBlock.isEmpty {
                            textBlocks.append(currentBlock)
                            currentBlock = ""
                        }
                    }
                }
                currentBlock += currentBlock.isEmpty ? recognizedText : "\n\(recognizedText)"
                previousRect = convertedRect
                if self.borderBoxView.frame.intersects(convertedRect) {
                    textInsideRectangle +=  textInsideRectangle.isEmpty ? recognizedText : "\n \(recognizedText)"
                    print("TEXT___\(recognizedText)")
//                    if recognizedText.contains(self.searchingString) {
//                        paragraphBoundingBox = convertedRect
//                        paragraphText = recognizedText
//
//                        // 🔥 If there's a previous box (above line), merge it and add previous text
//                        if let previousBox = previousBox, let prevText = previousText {
//                            paragraphBoundingBox = self.mergeBoxes(previousBox, convertedRect)
//                            paragraphText = prevText + "\n" + paragraphText
//                        }
//                    } else
                    if let existingBox = paragraphBoundingBox {
                        // 🔥 Only merge if text is **reasonably close** to the previous bounding box
                        let maxAllowedGap: CGFloat = 20 // Adjust based on spacing
                        if abs(existingBox.maxY - convertedRect.minY) < maxAllowedGap {
                            paragraphBoundingBox = self.mergeBoxes(existingBox, convertedRect)
                            paragraphText += "\n" + recognizedText
                        }
                    }
                }
                // 🔥 Store previous box and text to merge the upper line when needed
                previousBox = convertedRect
                previousText = recognizedText
            }
            if !currentBlock.isEmpty {
                textBlocks.append(currentBlock)
            }
            if paragraphBoundingBox == nil {
                var threeGroups = [String]()
                for (index, block) in textBlocks.enumerated() {
                    if block.split(separator: "\n").contains(where: { addressPredicate.evaluate(with: $0) }) {
                        print("Address detected in Block \(index + 1):")
                        print(block)
                        print("---------------------")
                        threeGroups.append(block)
                    }
                }
                //if group is less than 3 than add remaining random groups to send 3 groups to server
                if threeGroups.count < 3 {
                    for i in threeGroups.count..<3 {
                        if textBlocks.indices.contains(i) {
                            threeGroups.append(textBlocks[i])
                        }
                    }
                }
                if capturedImage != nil {
//                    removeAllSession()
//                    Task {
//                        let rescan = await self.showRescanAlert()
//                        if rescan {
//                            self.viewDidAppear(false)
//                        } else {
////                            self.imageAndNotMatchTextReceived?(self.capturedImage,threeGroups)
//                        }
//                    }
                    
                }
            } else
            if let paragraphBox = paragraphBoundingBox {
                self.detectedParagraphText = paragraphText
                print("FINAL PARAGRAPH:\(paragraphText)")
                self.drawBoundingBox(for: paragraphBox)
                if capturedImage != nil {
//                        removeAllSession()
//                    self.imageAndTextReceived?(capturedImage,textInsideRectangle)
                    }
            }
        }
    }

    func showRescanAlert(rescan: ((Bool)->Void)?) {
            let alert = UIAlertController(title: "Address not found",
                                          message: "Do you want to rescan?",
                                          preferredStyle: .alert)

            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                rescan?(true)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                rescan?(false)
            }))
            self.present(alert, animated: true)
    }
    
    func showRescanAlertWithOk(rescan: ((Bool)->Void)?) {
            let alert = UIAlertController(title: "No match found",
                                          message: "Please Rescan",
                                          preferredStyle: .alert)

            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                rescan?(true)
            }))
            self.present(alert, animated: true)
    }


    
//    func detectTextHandler2(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
//
//        DispatchQueue.main.async {
//            self.removePreviousBoundingBoxes()
//            self.detectedBoundingBoxes.removeAll()
//
//            var paragraphBoundingBox: CGRect?
//            var paragraphText = ""
//            var previousBox: CGRect?
//
//            for observation in observations {
//                guard let topCandidate = observation.topCandidates(1).first else { continue }
//                let recognizedText = topCandidate.string
//
//                let convertedRect = self.convertBoundingBox(observation.boundingBox)
//
//                // 🔥 Check if text is inside the border box
//                if self.borderBoxView.frame.intersects(convertedRect) {
//                    if recognizedText.contains(self.searchingString) {
//                        paragraphBoundingBox = convertedRect
//                        paragraphText = recognizedText
//
//                        // 🔥 If there's a previous box (above line), merge it
//                        if let previousBox = previousBox {
//                            paragraphBoundingBox = self.mergeBoxes(previousBox, convertedRect)
//                        }
//                    } else if let existingBox = paragraphBoundingBox {
//                        // 🔥 Only merge if text is **reasonably close** to the previous bounding box
//                        let maxAllowedGap: CGFloat = 20 // Adjust this based on spacing
//                        if abs(existingBox.maxY - convertedRect.minY) < maxAllowedGap {
//                            paragraphBoundingBox = self.mergeBoxes(existingBox, convertedRect)
//                            paragraphText += "\n" + recognizedText
//                        }
//                    }
//                }
//
//                // 🔥 Store previous box to consider merging the upper line
//                previousBox = convertedRect
//            }
//
//            // 🔥 Draw the optimized bounding box around the paragraph
//            if let paragraphBox = paragraphBoundingBox {
//                print("FINAL PARAGRAPH:\(paragraphText)")
//                self.drawBoundingBox(for: paragraphBox)
//            }
//        }
//    }


    func removePreviousBoundingBoxes() {
        DispatchQueue.main.async { [weak self] in
            self?.imageView.layer.sublayers?.removeAll { $0 is CALayer } // Remove all old rectangles
        }
    }
    
    func convertBoundingBox(_ boundingBox: CGRect) -> CGRect {
            let imageViewWidth = imageView.bounds.width
                let imageViewHeight = imageView.bounds.height
                // Vision's bounding box (normalized) starts from bottom-left; UIKit starts from top-left
                let x = boundingBox.origin.x * imageViewWidth
                let y = (1 - boundingBox.origin.y - boundingBox.height) * imageViewHeight
                let width = boundingBox.width * imageViewWidth
                let height = boundingBox.height * imageViewHeight

                return CGRect(x: x, y: y, width: width, height: height)
        }



    func drawBoundingBox(for boundingBox: CGRect) {
        DispatchQueue.main.async { [weak self] in
            let outline = CALayer()
            outline.frame = boundingBox//CGRect(x: xCord, y: yCord, width: width, height: height)
            outline.borderWidth = 3.0
            outline.borderColor = UIColor.green.cgColor

            self?.imageView.layer.addSublayer(outline)
            print("Drawing bounding box at: \(outline.frame)") // Debugging
        }
    }

    func mergeBoxes(_ box1: CGRect, _ box2: CGRect) -> CGRect {
        let minX = min(box1.minX, box2.minX)
        let maxX = max(box1.maxX, box2.maxX)
        let minY = min(box1.minY, box2.minY)
        let maxY = max(box1.maxY, box2.maxY)
        
        // 🔥 Reduce extra padding to avoid oversized boxes
            let padding: CGFloat = 5 // Adjust this to control extra space around text

            return CGRect(
                x: minX - padding,
                y: minY - padding,
                width: (maxX - minX) + (2 * padding),
                height: (maxY - minY) + (2 * padding)
            )
    }
    
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
   

    
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        frameCount += 1
//        if frameCount % 3 != 0 { return } // Process only every 3rd frame for efficiency
//
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        var requestOptions: [VNImageOption: Any] = [:]
//
//        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
//            requestOptions = [.cameraIntrinsics: camData]
//        }
//
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
//        guard let capturedImage = captureImage(from: sampleBuffer) else {
//                return
//            }
//        self.capturedImage = capturedImage
////        recognizeTextInImage(image: self.capturedImage)
//        do {
//            try imageRequestHandler.perform(requests)
//        } catch {
//            print("Error processing image: \(error)")
//        }
//    }

    func captureImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right) // Adjust orientation if needed
        }
        
        return nil
    }
    

    func isValidText(_ text: String) -> Bool {
        let pattern = "[a-zA-Z]+(?:[ -]?[0-9]+)*" // Allows letters, numbers, spaces, punctuation
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    struct TextBlock {
        var text: String
        var boundingBox: CGRect
    }

    
    func detectTextHandler2(request: VNRequest, error: Error?, pixelBuffer: CVPixelBuffer) {
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        DispatchQueue.main.async {
            self.detectedTextLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // Clear previous layers
            self.removePreviousBoundingBoxes()
            var textElements: [TextElementWithRect] = []
            
            for observation in observations {
                if let bestCandidate = observation.topCandidates(1).first {
                    let boundingBox = observation.boundingBox
                    
                    let imageSize = CGSize(
                        width: CVPixelBufferGetWidth(self.pixelBuffer!),
                        height: CVPixelBufferGetHeight(self.pixelBuffer!)
                    )
                    var rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
                    rect.origin.y = imageSize.height - rect.origin.y - rect.height
                    // Calculate the x and y coordinates of the text element
                    let x = Int(rect.origin.x)
                    let y = Int(rect.origin.y)
                    // Convert coordinates to match previewLayer
                    if let previewLayer = self.previewLayer {
                        let viewSize = previewLayer.bounds.size // Get the actual preview size
                        let convertedRect = self.convertBoundingBoxForRect(boundingBox, imageSize: imageSize, viewSize: viewSize)
                        // Append to text elements
                        if self.borderBoxView.frame.intersects(convertedRect) {
                            textElements.append(TextElementWithRect(text: bestCandidate.string, rect: convertedRect, x: x, y: y))
                            //                                    self.drawBoundingBox(for: textElements.last?.rect ?? CGRect())
                        }
                    }
                }
            }
            //self.drawBoundingBox(for: textElements.first?.rect ?? CGRect())
            // Group detected text elements
            guard textElements.count > 0 else {return}
            let groupedText = self.groupTextByPositionWithRect(textElements: textElements, yThreshold: 100, xThreshold: 60)
            
            // Draw rectangles around grouped text
//            for group in groupedText {
//                let mergedRect = self.mergeRects(rects: group.map { $0.rect })
//                let mappedArray = group.map {$0.text}.joined(separator: "\n")
//                if mappedArray.contains(self.street) || mappedArray.contains(self.postal) {
//                    self.foundMatchedGroup = true
//                    self.drawBoundingBox(for: mergedRect)
//                }
//                self.detectedGroups.append(TextGroup(textElements: group, rect: mergedRect))
//            }
            let filteredGroups = groupedText.filter { group in
                group.contains { element in
                    element.text.contains(self.street) || element.text.contains(self.postal)
                }
            }
            if filteredGroups.count == 0 {
                let addressArray = groupedText.flatMap { group in
                    group.filter { element in
                        element.text.containsAddress()
                    }
                }
                let addressGroup = groupedText.first { group in
                    let hasStreet = group.contains { $0.text.range(of: #"(\d{1,5})\s\w+"#, options: .regularExpression) != nil }
                    let hasCityStateZip = group.contains { $0.text.range(of: #"\b[A-Z]{2}\.?\s+\d{5}(-\d{4})?\b"#, options: .regularExpression) != nil }
                    return hasStreet && hasCityStateZip
                }
            }
//            for group in groupedText {
//                let mergedRect = self.mergeRects(rects: group.map { $0.rect })
//                let mappedArray = group.map {$0.text}.joined(separator: "\n")
//                if mappedArray.contains(self.street) || mappedArray.contains(self.postal) {
//                    self.foundMatchedGroup = true
//                    self.drawBoundingBox(for: mergedRect)
//                }
//                self.detectedGroups.append(TextGroup(textElements: group, rect: mergedRect))
//            }
        }
    }

    func recognizeTextInImage(image: UIImage?) async -> String {
        guard let cgImage = image?.cgImage else { return "" }
        var extractedText = ""
        // Create a Vision request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a text recognition request
        return await withCheckedContinuation { continuation in
            
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                
                // Extract text elements with their bounding box coordinates
                var textElements: [TextElementWithRect] = []
                
                for observation in observations {
                    if let bestCandidate = observation.topCandidates(1).first {
                        let boundingBox = observation.boundingBox
                        
                        let imageSize = CGSize(
                            width: cgImage.width,
                            height: cgImage.height
                        )
                        var rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
                        rect.origin.y = imageSize.height - rect.origin.y - rect.height
                        // Calculate the x and y coordinates of the text element
                        let x = Int(rect.origin.x)
                        let y = Int(rect.origin.y)
                        // Convert coordinates to match previewLayer
                        if let previewLayer = self.previewLayer {
                            let viewSize = previewLayer.bounds.size // Get the actual preview size
                            let convertedRect = self.convertBoundingBoxForRect(boundingBox, imageSize: imageSize, viewSize: viewSize)
                            // Append to text elements
                            if self.borderBoxView.frame.intersects(convertedRect) {
                                textElements.append(TextElementWithRect(text: bestCandidate.string, rect: convertedRect, x: x, y: y))
                                //                                    self.drawBoundingBox(for: textElements.last?.rect ?? CGRect())
                            }
                        }
                    }
                }
                guard textElements.count > 0 else {return}
                let groupedText = self.groupTextByPositionWithRect(textElements: textElements, yThreshold: 100, xThreshold: 60)
                let filteredGroups = groupedText.filter { group in
                    group.contains { element in
                        element.text.lowercased().contains(self.street.lowercased()) || element.text.lowercased().contains(self.postal.lowercased())
                    }
                }
                if filteredGroups.count > 0 {
                    extractedText = filteredGroups
                        .map { $0.map { $0.text }.joined(separator: "\n") }
                        .joined(separator: "\n")
                    continuation.resume(returning: extractedText)
                } else {
                    let mappedArray = groupedText.map { group in
                        group.map { $0.text }.joined(separator: "\n")
                    }
                    extractedText = mappedArray.first(where: {$0.containsAddress()}) ?? ""
                    continuation.resume(returning: extractedText)
                }
            }
            
            request.usesLanguageCorrection = true
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
   
    
    func isValidPostalAddress(_ text: String) -> Bool {
        let pattern = "^[0-9a-zA-Z,\\.\\-#& ]+$" // Allows numbers, letters, commas, hyphens, dots, and spaces
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    // Struct to represent a text element
    struct TextElement {
        let text: String
        let x: Int
        let y: Int
    }

    // Function to group text elements based on position
    func groupTextByPosition(textElements: [TextElement], yThreshold: Int = 10, xThreshold: Int = 5) -> [[String]] {
        // Step 1: Sort text elements by Y-coordinate (top-to-bottom) and then by X-coordinate (left-to-right)
        let yThreshold = 150  // Adjust as needed
        let xThreshold = 60 // Prevents distant X values from interfering
        
        let sortedElements = textElements.sorted { (a,b) in
            if abs(a.x - b.x) <= xThreshold && abs(a.y - b.y) <= yThreshold {
                return false // Maintain order if X difference is small
            }
            return a.x < b.x // Otherwise, sort by X
        }


//         Initialize variables
        var groups: [[String]] = []
        var currentGroup: [String] = [sortedElements[0].text]

        // Step 2: Iterate through each text element
        for i in 1..<sortedElements.count {
            let currentText = sortedElements[i].text
            let currentX = sortedElements[i].x
            let currentY = sortedElements[i].y

            // Skip empty text
            if currentText.isEmpty {
                continue
            }
            if abs(currentX - sortedElements[i - 1].x) <= xThreshold &&  abs(currentY - sortedElements[i - 1].y) <= yThreshold {
                currentGroup.append(currentText)
            } else {
                groups.append(currentGroup)
                currentGroup = [currentText]
            }
        }
        return groups
    }
    
    func groupTextByPositionWithRect(textElements: [TextElementWithRect], yThreshold: Int, xThreshold: Int) -> [[TextElementWithRect]] {
        // Step 1: Sort text elements by Y-coordinate (top-to-bottom) and then by X-coordinate (left-to-right)
//        let yThreshold = yThreshold  // Adjust as needed
//        let xThreshold = xThreshold // Prevents distant X values from interfering
        
        let sortedElements = textElements.sorted { (a,b) in
            if abs(a.x - b.x) <= xThreshold && abs(a.y - b.y) <= yThreshold {
                return false // Maintain order if X difference is small
            }
            return a.x < b.x // Otherwise, sort by X
        }


//         Initialize variables
        var groups: [[TextElementWithRect]] = []
        var currentGroup: [TextElementWithRect] = [sortedElements[0]]

        // Step 2: Iterate through each text element
        for i in 1..<sortedElements.count {
            let currentText = sortedElements[i].text
            let currentX = sortedElements[i].x
            let currentY = sortedElements[i].y

            // Skip empty text
            if currentText.isEmpty {
                continue
            }
            if abs(currentX - sortedElements[i - 1].x) <= xThreshold &&  abs(currentY - sortedElements[i - 1].y) <= yThreshold {
                currentGroup.append(sortedElements[i])
            } else {
                groups.append(currentGroup)
                currentGroup = [sortedElements[i]]
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        return groups
    }
    
//    func groupTextByPositionWithRect(textElements: [TextElementWithRect], yThreshold: CGFloat, xThreshold: CGFloat) -> [[TextElementWithRect]] {
//        var groups: [[TextElementWithRect]] = []
//            
//            for element in textElements {
//                var added = false
//                for i in 0..<groups.count {
//                    if let last = groups[i].last {
//                        let yClose = abs(last.rect.origin.y - element.rect.origin.y) < yThreshold
//                        let xClose = abs(last.rect.origin.x - element.rect.origin.x) < xThreshold
//                        
//                        if yClose || xClose {
//                            groups[i].append(element)
//                            added = true
//                            break
//                        }
//                    }
//                }
//                if !added {
//                    groups.append([element])
//                }
//            }
//            
//            return groups
//    }

    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.sampleBuffer = sampleBuffer
        guard scanState == .started else {return}
        frameCount += 1
        if frameCount % 2 != 0 { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.pixelBuffer = pixelBuffer
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.detectTextHandler2(request: request, error: error, pixelBuffer: pixelBuffer)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
    
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            print("Failed to capture image")
            return
        }
//        self.imageViewer.image = uiImage
//        view.bringSubviewToFront(self.imageViewer)
        // Set captured image for OCR
        self.capturedImage = uiImage
        
        // Process the high-quality image with OCR
        //recognizeTextInImage(image: uiImage)
    }
}

extension CameraViewController: AddressListDelegate {
    func didTapSubmit(isMatched: Bool, text: String) {
        if isMatched {
            self.imageAndTextReceived?(capturedImage, text)
        } else {
            self.imageAndTextReceived?(capturedImage, text)
//            self.imageAndNotMatchTextReceived?(capturedImage, [text])
        }
    }
}

extension String {
    func containsAddress() -> Bool {
        let pattern = #"(?i)\b(\d{1,6}\s[A-Za-z\s]+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Way|Dr|Drive|Court|Ct|Place|Pl|Square|Sq|Trail|Trl|Parkway|Pkwy|Circle|Cir))\b|\b([A-Za-z\s]+,\s?[A-Z]{2}\s\d{5}(-\d{4})?)\b"#
        
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}
