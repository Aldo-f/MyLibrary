import UIKit
import AVFoundation

/*
 Voor het scannen van de barcode heb ik deze tutorial gevolgd: https://www.appcoda.com/simple-barcode-reader-app-swift/
 */
class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    @IBOutlet weak var container: UIView!
    var barcode: String?
    
    override func viewDidLoad() {
        self.configureISBNScanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        if (session?.isRunning == false) {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (session?.isRunning == true) {
            session.stopRunning()
        }
    }
    
    func configureISBNScanner() {
        // Create a session object.
        session = AVCaptureSession()
        
        // Set the captureDevice.
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        // Create input object.
        let videoInput: AVCaptureDeviceInput?
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
        } catch {
            return
        }
        
        // Add input to the session.
        if (session.canAddInput(videoInput!)) {
            session.addInput(videoInput!)
        } else {
            scanningNotPossible()
        }
        
        // Create output object.
        let metadataOutput = AVCaptureMetadataOutput()
        
        // Add output to the session.
        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)
            
            // Send captured data to the delegate object via a serial queue.
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Set barcode type for which to scan: EAN-13.
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13]
            
        } else {
            scanningNotPossible()
        }
        
        // Add previewLayer and have it show the video data.
        previewLayer = AVCaptureVideoPreviewLayer(session: session);
        previewLayer.frame = container.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        container.layer.addSublayer(previewLayer)
        
        // Begin the capture session.
        session.startRunning()
    }
    
    func scanningNotPossible() {
        // Let the user know that scanning isn't possible with the current device.
        let alert = UIAlertController(title: "Scannen lukt niet", message: "Probeer met een toestel dat wel scannen via de camera ondersteunt.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        session = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        // Get the first object from the metadataObjects array.
        if let barcodeData = metadataObjects.first {
            // Turn it into machine readable code
            let barcodeReadable = barcodeData as? AVMetadataMachineReadableCodeObject;
            if let readableCode = barcodeReadable {
                // Send the barcode as a string to barcodeDetected()
                barcodeDetected(code: readableCode.stringValue!);
            }
            
            // Vibrate the device to give the user some feedback.
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Avoid a very buzzy device.
            session.stopRunning()
        }
    }

    func barcodeDetected(code: String) {
        
        // Remove the spaces.
        let trimmedCode = code.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        // EAN or UPC?
        // Check for added "0" at beginning of code.
        
        let trimmedCodeString = "\(trimmedCode)"
        
        if trimmedCodeString.hasPrefix("0") && trimmedCodeString.count > 1 {
            self.barcode = String(trimmedCodeString.dropFirst())
        } else {
            self.barcode = trimmedCodeString
        }
        
        self.performSegue(withIdentifier: "didScanBarcode", sender: self)
    }
}
