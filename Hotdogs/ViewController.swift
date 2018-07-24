//
//  ViewController.swift
//  Hotdogs
//
//  Created by Zulwiyoza Putra on 23/07/18.
//  Copyright © 2018 Wiyoza. All rights reserved.
//

import UIKit
import FirebaseMLVision

class ViewController: UIViewController {
    @IBOutlet weak var imageViewContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var sublabel: UILabel!
    @IBOutlet weak var analyzeButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    var imagePickerController: UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = self
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        analyzeButton.setShadow()
        takePhotoButton.setShadow()
        imageViewContainer.setShadow()
        imageView.layer.cornerRadius = 12.0
        self.analyzeButton.isEnabled = false
        self.analyzeButton.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
}

extension ViewController {
    @IBAction func takePhoto(_ sender: UIButton) {
        present(imagePickerController, animated: true)
    }

    @IBAction func analyzePhoto(_ sender: UIButton) {
        guard let image = imageView.image else { fatalError("No image found in imageView") }
        
        self.sublabel.text = ""
        self.label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.label.text = "Finding out..."
        self.analyzeButton.isEnabled = false
        self.analyzeButton.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        Firebase.shared.analyzeImageCloudly(image) { (visionCloudLabels, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    self.label.text = error!.localizedDescription
                }
                return
            }
            
            guard let visionCloudLabels = visionCloudLabels else {
                DispatchQueue.main.async {
                    self.label.text = "Couldn't find any object in the photo"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.displayResult(visionCloudLabels: visionCloudLabels)
            }
        }
    }
    
    private func displayResult(visionCloudLabels: [VisionCloudLabel]) {
        var isHotDog = false
        for visionCloudLabel in visionCloudLabels {
            if visionCloudLabel.label == "hot dog" {
                if visionCloudLabel.confidence as! Double > 0.5 {
                    isHotDog = true
                    break
                }
            }
        }
        
        if isHotDog {
            self.label.text = "It's a Hot Dog"
            self.label.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        } else {
            self.label.text = "It's not a Hot Dog"
            self.label.textColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
            if visionCloudLabels.count < 2 {
                self.sublabel.text = "It's may be \(visionCloudLabels[0].label!)"
            } else if visionCloudLabels.count > 1 {
                if visionCloudLabels[0].confidence as! Double > 0.90 {
                    self.sublabel.text = "It's probably a \(visionCloudLabels[0].label!)"
                } else {
                    self.sublabel.text = "It's probably a \(visionCloudLabels[0].label!) or \(visionCloudLabels[1].label!)"
                }
            }
        }
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if picker.allowsEditing {
            guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { fatalError("No image found") }
            imageView.image = image
        } else {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { fatalError("No image found") }
            imageView.image = image
        }
        analyzeButton.isEnabled = true
        analyzeButton.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        label.text = "Please analyze to find out"
        sublabel.text = ""
        label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

class Firebase {
    private var vision: Vision
    
    static var shared: Firebase = {
        return Firebase()
    }()
    
    init() {
        self.vision = Vision.vision()
    }
    
    private lazy var localVisionLabelDetector: VisionLabelDetector = {
        return vision.labelDetector()
    }()
    
    private lazy var visionCloudLabelDetector: VisionCloudLabelDetector = {
        return vision.cloudLabelDetector()
    }()
    
    private func getVisionImage(_ image: UIImage) -> VisionImage {
        let resizedImage = image.resize(400.0)
        return VisionImage(image: resizedImage)
    }

    typealias LocalImageLabellingCompletionHandler = ((_ visionLabels: [VisionLabel]?,_ error: Error?) -> Void)?
    func analyzeImageLocally(_ image: UIImage, completionHandler: LocalImageLabellingCompletionHandler = nil) {
        let visionImage = getVisionImage(image)
        localVisionLabelDetector.detect(in: visionImage) { (visionLabels: [VisionLabel]?, error: Error?) in
            guard let handler = completionHandler else { return }
            handler(visionLabels, error)
        }
    }
    
    typealias CloudImageLabellingCompletionHandler = ((_ visionLabels: [VisionCloudLabel]?,_ error: Error?) -> Void)?
    func analyzeImageCloudly(_ image: UIImage, completionHandler: CloudImageLabellingCompletionHandler = nil) {
        let visionImage = getVisionImage(image)
        visionCloudLabelDetector.detect(in: visionImage) { (visionCloudLabels: [VisionCloudLabel]?, error: Error?) in
            guard let handler = completionHandler else { return }
            handler(visionCloudLabels, error)
        }
    }
}

extension UIView {
    func setShadow() {
        self.layer.cornerRadius = 12.0
        self.layer.shadowRadius = 8.0
        self.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
    }
}

extension UIImage {
    private func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func resize(_ maxSize: Float) -> UIImage {
        let maxSize = CGFloat(maxSize)
        let ratio = self.size.height/self.size.width
        if ratio > 1 {
            let size = CGSize(width: maxSize, height: maxSize * ratio)
            return self.resize(targetSize: size)
        } else {
            let size = CGSize(width: maxSize * ratio, height: maxSize)
            return self.resize(targetSize: size)
        }
    }
}
