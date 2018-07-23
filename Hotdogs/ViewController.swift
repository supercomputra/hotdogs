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
    
    var vision: Vision?
    
    var imagePickerController: UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = self
        return controller
    }
    
    lazy var localVisionLabelDetector: VisionLabelDetector = {
        guard let vision = vision else { fatalError("Vision is not set") }
        return vision.labelDetector()
    }()
    
    lazy var cloudVisionLabelDetector: VisionCloudLabelDetector = {
        guard let vision = vision else { fatalError("Vision is not set") }
        return vision.cloudLabelDetector()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vision = Vision.vision()
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
        self.sublabel.text = ""
        self.label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.label.text = "Finding out..."
        self.analyzeButton.isEnabled = false
        self.analyzeButton.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        analyzeImageCloudly { (visionCloudLabels, error) in
            self.analyzeButton.isEnabled = true
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
                DispatchQueue.main.async {
                    self.label.text = "It's a Hot Dog"
                    self.label.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
                }
            } else {
                DispatchQueue.main.async {
                    self.label.text = "It's not a Hot Dog"
                    self.label.textColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                }
                
                if visionCloudLabels.count < 2 {
                    DispatchQueue.main.async {
                        self.sublabel.text = "It's may be \(visionCloudLabels[0].label!)"
                    }
                    
                } else if visionCloudLabels.count > 1 {
                    if visionCloudLabels[0].confidence as! Double > 0.90 {
                        DispatchQueue.main.async {
                            self.sublabel.text = "It's probably a \(visionCloudLabels[0].label!)"
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.sublabel.text = "It's probably a \(visionCloudLabels[0].label!) or \(visionCloudLabels[1].label!)"
                        }
                    }
                }
            }
        }
    }
}

extension ViewController {
    func analyzeImageLocally(completionHandler: ((_ visionLabels: [VisionLabel]?,_ error: Error?) -> Void)? = nil) {
        guard let visionImage = imageView.getVisionImage() else { return }
        
        localVisionLabelDetector.detect(in: visionImage) { (visionLabels: [VisionLabel]?, error: Error?) in
            guard let handler = completionHandler else { return }
            handler(visionLabels, error)
        }
    }
    
    func analyzeImageCloudly(completionHandler: ((_ visionCloudLabels: [VisionCloudLabel]?,_ error: Error?) -> Void)? = nil) {
        guard let visionImage = imageView.getVisionImage() else { return }
        
        cloudVisionLabelDetector.detect(in: visionImage) { (visionCloudLabels: [VisionCloudLabel]?, error: Error?) in
            guard let handler = completionHandler else { return }
            handler(visionCloudLabels, error)
        }
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if picker.allowsEditing {
            guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
                fatalError("No image found")
            }
            self.analyzeButton.isEnabled = true
            self.analyzeButton.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            imageView.image = image
        } else {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                fatalError("No image found")
            }
            self.analyzeButton.isEnabled = true
            self.analyzeButton.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            imageView.image = image
        }
        
        label.text = "Please analyze to find out"
        sublabel.text = ""
        self.label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

extension UIView {
    func setShadow() {
        self.layer.cornerRadius = 12.0
        self.layer.shadowRadius = 4.0
        self.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
    }
}

extension UIImageView {
    func getVisionImage() -> VisionImage? {
        guard let image = self.image else { return nil }
        let ratio = image.size.height/image.size.width
        let maxSize = CGFloat(400.0)
        if ratio > 1 {
            let size = CGSize(width: maxSize, height: maxSize * ratio)
            return VisionImage(image: image.resize(targetSize: size))
        } else {
            let size = CGSize(width: maxSize * ratio, height: maxSize)
            return VisionImage(image: image.resize(targetSize: size))
        }
    }
}

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
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
}
