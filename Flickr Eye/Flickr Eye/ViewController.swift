//  ViewController.swift
//  Flickr Eye
//  Created by Pouria Sanae on 3/14/15.
//  Copyright (c) 2015 Pouria Sanae. All rights reserved.

//To do:
// make Color search
// make object search
// Cut image
// send 5 images and compaire result
// Chnage "I see" to melody
// add Live view 
//
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var myTextLabel: UITextView!
    @IBOutlet weak var zoomImage: UIImageView!
    @IBOutlet weak var didPressTakePhoto: UIButton!
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var takePictureButton: UIButton!
    
    let picker = UIImagePickerController()
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var busyWaiting : Bool = false
    var hasAlreadyStarted : Bool = false
    var switchIsOn: Bool = false
    enum searchTypes : Int {
        case Object
        case Color
        case currency
    }
    var searchSetting = searchTypes.Object
    
    
    
    //* * * Override Functions * * *
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self  //Delegate is used to segaue back to its self
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            welcomeIntroCamera()
        } else {
            welcomeIntroNoCamera()
        }
    }
    override func viewDidAppear(animated: Bool) {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil { // no Camera
            //Using the previewView is placeholder for camera view
            previewLayer!.frame = previewView.bounds
        }
    }
    override func viewWillAppear(animated: Bool) {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) == nil { return  } // no Camera
        
        //AVCaptureSessionPresetPhoto  //Original
        //AVCaptureSessionPresetLow
        //AVCaptureSessionPresetMedium
        //AVCaptureSessionPresetHigh
        //AVCaptureSessionPreset352x288
        //AVCaptureSessionPreset640x480
        //AVCaptureSessionPresetiFrame960x540
        //AVCaptureSessionPreset1280x720
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset1280x720
        
        //Select camer, defaul is the rear camera
        var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error: NSError?
        var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewView.layer.addSublayer(previewLayer)
                captureSession!.startRunning()
            }
        }
        
    }
    
    
    
    //* * * Actions * * *
    @IBAction func getFileFromLib(sender: UIBarButtonItem) {
        picker.allowsEditing = false       //Tell the picker we want a whole picture, not an edited version.
        picker.sourceType = .PhotoLibrary  //Set the source type to the photo library
        picker.modalPresentationStyle = .Popover  // use for IPAD style
        presentViewController(picker, animated: true, completion: nil)//4
        picker.popoverPresentationController?.barButtonItem = sender
    }
    @IBAction func didPressTakePhoto(sender: UIButton) {
        takePhoto()
    }
    @IBAction func searchChange(sender: UIBarButtonItem) {
        stateChanged()
    }
    
    
    
    //* * * Delegates for Photo Library * * *
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        var chosenImage = info[UIImagePickerControllerOriginalImage] as UIImage
        // need to change the isze of the image here
        //http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
        dismissViewControllerAnimated(true, completion: {
            self.sendImagePOST(chosenImage)
            self.capturedImage.contentMode = .ScaleAspectFit
            self.capturedImage.image = chosenImage
        })
    }
    
    
    func stateChanged() {
        switch self.searchSetting {
        case .Object:
            self.searchSetting = .Color
            self.outputTextAndVoice("Color mode", speechRate :0.008, textEnable : true)
        case .Color:
            self.searchSetting = .currency
            self.outputTextAndVoice("Currency mode", speechRate :0.008, textEnable : true)
        case .currency:
            self.searchSetting = .Object
            self.outputTextAndVoice("Object mode", speechRate :0.008, textEnable : true)
        default:
            self.searchSetting = .Object
            self.outputTextAndVoice("Object mode", speechRate :0.008, textEnable : true)
            break
        }
    }
    
    func takePhoto(){
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) == nil { return } // no Camera
        hasAlreadyStarted = true // stops the welcome mesage text output
        if self.busyWaiting == false {
            self.takePictureButton.enabled = false
            self.busyWaiting = true
            self.zoomImage.hidden = true
            if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                    if (sampleBuffer != nil) {
                        var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        var dataProvider = CGDataProviderCreateWithCFData(imageData)
                        var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                        var myimage = UIImage(CGImage: cgImageRef, scale: 1, orientation: UIImageOrientation.Right)
                        
                        self.sendImagePOST(myimage) // send image to the server
                        
                        
                        self.capturedImage.image = myimage
                        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                    }
                })
            }
            
        }
    }
    
    
    let manager = AFHTTPRequestOperationManager()
    func sendImagePOST(myimage : UIImage!){
        //// change parameters: nil, to parameters: params,
        //var params = [ "familyId":"10000",
        //    "contentBody" : "Some body content for the test application",
        //    "name" : "the name/title", "typeOfContent":"photo" ]
        
        if self.switchIsOn == false {
            println(" ")
            println("=======================================================================================================")
            println(" ")
            self.outputTextAndVoice("One second please...", speechRate :0.1)
        }
        
        //var imageData = UIImagePNGRepresentation(myimage)
        var imageData = UIImageJPEGRepresentation(myimage, 1.0) //max=1.0
        if imageData != nil{
            
            //let postURL = "http://requestb.in/powu8hpo"
            //let postURL = "http://molestdepressed.corp.gq1.yahoo.com:8000/api2"
            let postURL = "http://molestdepressed.corp.gq1.yahoo.com:8000/api"
            
            //let manager = AFHTTPRequestOperationManager()
            // "text/plain, text/html, application/json, audio/wav, application/octest-stream")
            manager.responseSerializer.acceptableContentTypes = NSSet(objects: "text/html")
            manager.POST(postURL, parameters: nil,
                constructingBodyWithBlock: { (data: AFMultipartFormData!) in
                    data.appendPartWithFileData(imageData, name: "file", fileName: "image.jpg", mimeType: "image/jpeg")
                },
                success: { (operation: AFHTTPRequestOperation!,response: AnyObject!) in //operation, response in
                    
                    self.takePictureButton.enabled = true
                    self.busyWaiting = false
                    self.zoomImage.hidden = false
                    self.dictionaryToArray(response)
                    
                    if self.switchIsOn == true { self.takePhoto()  }
                },
                failure: { operation, error in
                    println("[fail] operation: \(operation), error: \(error)")
                    self.takePictureButton.enabled = true
                    self.busyWaiting = false
                    self.zoomImage.hidden = false
                    self.outputTextAndVoice("Signal lost. Please connect and try again.", speechRate :0.06)
                }
            )
        }
    }
    
    
    func dictionaryToArray_old(response: AnyObject)  { // -> [String] {
        let exceptionString : String = "outdoor indoor minimalism monochrome blackandwhite blackandwhite depth of field blur abstract vintage empty"
        
        //println(response)
        
        if let receiver = response as? NSArray {
            var d = receiver as NSArray
            if d.count > 0 {
                var myArray:[(name: String, value: Float)] = []
                for element in d {
                    var myNum : Float = element[1]  as Float
                    var myTag : String = element[0]  as String
                    //println(myNum)
                    //println(myTag)
                    myArray += [(name: myTag, value: myNum)]
                }
                myArray.sort { $0.0 == $1.0 ?  $0.0 > $1.0 : $0.1 > $1.1 }
                println(myArray)
                println(" ")
                var i = 0
                if self.switchIsOn == false { //camera mode
                    var outputString = "I see "
                    for myTupels in myArray{
                        if (exceptionString.rangeOfString(myTupels.name) == nil ) || (myArray.count < 4) {
                            i++
                            if i > 2 {
                                outputString += "and " + colorOrNot(myTupels.name)
                                break
                            }
                            outputString += colorOrNot(myTupels.name) + ", "
                        }
                    }
                    if outputString != "I see " {
                        self.outputTextAndVoice(outputString, speechRate :0.06)
                    } else {
                        self.outputTextAndVoice("Try again.", speechRate :0.06)
                    }
                } else { //Video mode
                    var outputString = ""
                    for myTupels in myArray{
                        if exceptionString.rangeOfString(myTupels.name) == nil{
                            i++
                            if i > 1 {
                                outputString += colorOrNot(myTupels.name) + " "
                                break
                            }
                        }
                    }
                    if outputString != " " {
                        self.outputTextAndVoice(outputString, speechRate :0.06)
                    }
                }
                
            } else{
                //empty result
                self.outputTextAndVoice("Try again.", speechRate :0.06)
            }
            
        } else {
            println("Bad Dictionary")
        }
    }
    
    
    func dictionaryToArray(response: AnyObject)  { // -> [String] {
        let exceptionString : String = "outdoor indoor minimalism monochrome blackandwhite blackandwhite depth of field blur abstract vintage empty"
        println(response)
        if let receiver = response as? NSDictionary {
            var d = receiver as Dictionary
            if d.count > 0 {
                var myArray:[(name: String, value: Float)] = []
                for (autotag, numbers) in d {
                    var myNum : Float = numbers as Float
                    var myTag : String = autotag as String
                    //println(myNum)
                    //println(myTag)
                    myArray += [(name: myTag, value: myNum)]
                }
                myArray.sort { $0.0 == $1.0 ?  $0.0 > $1.0 : $0.1 > $1.1 }
                //println(myArray)
                println(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                var i = 0
                if self.switchIsOn == false { //camera mode
                    var outputString = "I see "
                    for myTupels in myArray{
                        if exceptionString.rangeOfString(myTupels.name) == nil{
                            i++
                            if i > 2 {
                                outputString += "and " + colorOrNot(myTupels.name)
                                break
                            }
                            outputString += colorOrNot(myTupels.name) + ", "
                        }
                    }
                    if outputString != "I see " {
                        self.outputTextAndVoice(outputString, speechRate :0.06)
                    } else {
                        self.outputTextAndVoice("Try again.", speechRate :0.06)
                    }
                } else { //Video mode
                    var outputString = ""
                    for myTupels in myArray{
                        if exceptionString.rangeOfString(myTupels.name) == nil{
                            i++
                            if i > 1 {
                                outputString += colorOrNot(myTupels.name) + " "
                                break
                            }
                        }
                    }
                    if outputString != " " {
                        self.outputTextAndVoice(outputString, speechRate :0.06)
                    }
                }
                
            } else{
                //empty result
                self.outputTextAndVoice("Try again.", speechRate :0.06)
            }
            
        } else {
            println("Bad Dictionary")
        }
    }
    
    func colorOrNot (inputString: String) -> String {
        let colorString : String = "monochrome blackandwhite white background aposematic coloration black blue ultramarine blue chromatic gold gray green magenta monochrome neon orange pink purple crimson fuschia maroon red reddish teal white yellow "
        
        if colorString.rangeOfString(inputString) != nil{
            return  "the color " + inputString
        }else{
            return inputString
        }
    }
    
    //* * * Output text and Vocie * * *
    var synth = AVSpeechSynthesizer()
    func outputTextAndVoice (myText : String, speechRate : Float = 0.05, textEnable : Bool = true) {
        //enum AVSpeechBoundary : Int { case Immediate    case Word  }
        var mySpeechStoper = AVSpeechBoundary.Immediate
        synth.stopSpeakingAtBoundary(mySpeechStoper)
        
        if textEnable {
            self.myTextLabel.text = myText
            println(myText)
        }
        var myUtterance = AVSpeechUtterance(string: "")
        myUtterance = AVSpeechUtterance(string: myText)
        myUtterance.rate = speechRate
        myUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speakUtterance(myUtterance)
    }
    
    
    //* * * Welcome messages * * *
    func welcomeIntroNoCamera() {
        self.takePictureButton.enabled = false
        self.zoomImage.hidden = true
        self.outputTextAndVoice("Hello, ... I'm your seeing assistant, ....Choose an image from your photo library, and I will view it for you...", speechRate :0.06, textEnable : false)
        self.myTextLabel.text = "Hello... "
        self.delay(1) {
            if self.hasAlreadyStarted==false {
                self.myTextLabel.text = "I'm your seeing assistant."
            }
            self.delay(2) {
                if self.hasAlreadyStarted==false {
                    self.myTextLabel.text = "Choose and image from your photo library and I will view it for you."
                }
            }
        }
        
    }
    func welcomeIntroCamera() {
        self.myTextLabel.text = "Hello... "
        self.outputTextAndVoice("Hello", speechRate :0.06, textEnable : false)
        self.delay(1) {
            if self.hasAlreadyStarted==false {
                self.myTextLabel.text = "and Welcome to Flickr Eye."
                self.outputTextAndVoice("and welcome to Flickr Eye .", speechRate :0.06, textEnable : false)
            }
            self.delay(2) {
                if self.hasAlreadyStarted==false {
                    self.myTextLabel.text = "Flickr Eye is an IOS application developed specifically for the blind and people with low vision"
                    self.outputTextAndVoice("Flickr Eye is an IOS application developed specifically for the blind and people with low vision ", speechRate :0.06, textEnable : false)
                }
                self.delay(5.7) {
                    if self.hasAlreadyStarted==false {
                        self.myTextLabel.text = "Utilizing the potential of Flickr vision technology..."
                        self.outputTextAndVoice("Utilizing the potential of Flickr vision technology", speechRate :0.06, textEnable : false)
                    }
                    self.delay(3.8) {
                        if self.hasAlreadyStarted==false {
                            self.myTextLabel.text = "This app is intended to assist blinds with everyday tasks..."
                            self.outputTextAndVoice("This app is intended to assist blinds with everyday tasks", speechRate :0.06, textEnable : false)
                        }
                        self.delay(3.3) {
                            if self.hasAlreadyStarted==false {
                                self.myTextLabel.text = "increase independence..."
                                self.outputTextAndVoice("increase independence", speechRate :0.06, textEnable : false)
                            }
                            self.delay(2.1) {
                                if self.hasAlreadyStarted==false {
                                    self.myTextLabel.text = "and generally make things easier."
                                    self.outputTextAndVoice("and generally make things easier", speechRate :0.06, textEnable : false)
                                }
                                self.delay(2.4) {
                                    if self.hasAlreadyStarted==false {
                                        self.myTextLabel.text = "So lets start!"
                                        self.outputTextAndVoice("So lets start", speechRate :0.06, textEnable : false)
                                    }
                                    self.delay(1.4) {
                                        if self.hasAlreadyStarted==false {
                                            self.myTextLabel.text = "Point your phone in the direction that you would like to see"
                                            self.outputTextAndVoice("Point your phone in the direction that you would like to see", speechRate :0.06, textEnable : false)
                                        }
                                        self.delay(2.5) {
                                            if self.hasAlreadyStarted==false {
                                                self.myTextLabel.text = "Tap on the screen."
                                                self.outputTextAndVoice("and tap on the screen", speechRate :0.06, textEnable : false)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        /*
        self.outputTextAndVoice("Hello, ... I'm your seeing assistant, ....Point your phone in the direction that you would like to see, ... and tap on the screen.", speechRate :0.06, textEnable : false)
        self.myTextLabel.text = "Hello... "
        self.delay(1) {  if self.hasAlreadyStarted==false { self.myTextLabel.text = "I'm your seeing assistant." }
        self.delay(2) { if self.hasAlreadyStarted==false { self.myTextLabel.text = "Point your phone in the direction that you would like to see..." }
        self.delay(2.5) { if self.hasAlreadyStarted==false { self.myTextLabel.text = "Tap on the screen." } }
        }
        }
        */
    }
    
    //* * * Delay function * * *
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }



}

