//  ViewController.swift
//  Flickr Eye
//  Created by Pouria Sanae on 3/14/15.
//  Copyright (c) 2015 Pouria Sanae. All rights reserved.

//To do:
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
    
    @IBOutlet weak var cropImg1: UIImageView!
    @IBOutlet weak var cropImg2: UIImageView!
    @IBOutlet weak var cropImg3: UIImageView!
    @IBOutlet weak var cropImg4: UIImageView!
    
    
    let picker = UIImagePickerController()
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var busyWaiting : Bool = false
    var hasAlreadyStarted : Bool = false
    var myResultArray:[(name: String, value: Float)] = []
    var cropCount = 0
    enum searchTypes : Int {
        case Object
        case Color
        case Currency
        case Live
        case Test
    }
    var searchSetting = searchTypes.Object
    let colorString : String = "monochrome blackandwhite white background aposematic coloration black blue ultramarine blue chromatic gold gray green magenta monochrome neon orange pink purple crimson fuschia maroon red reddish teal white yellow "
    let exceptionString : String = "outdoor indoor minimalism depth of field blur abstract vintage empty"
    
    
    //* * * Override Functions * * *
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self  //Delegate is used to segaue back to its self
        
        //hide all test images
        self.cropImg1.hidden = true
        self.cropImg2.hidden = true
        self.cropImg3.hidden = true
        self.cropImg4.hidden = true
        
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
        
        //hide all test images
        self.cropImg1.hidden = true
        self.cropImg2.hidden = true
        self.cropImg3.hidden = true
        self.cropImg4.hidden = true
        
        //AVCaptureSessionPresetPhoto  //Original
        //AVCaptureSessionPresetLow
        //AVCaptureSessionPresetMedium
        //AVCaptureSessionPresetHigh
        //AVCaptureSessionPreset352x288
        //AVCaptureSessionPreset640x480
        //AVCaptureSessionPresetiFrame960x540
        //AVCaptureSessionPreset1280x720
        captureSession = AVCaptureSession()
        println("640x480")
        captureSession!.sessionPreset = AVCaptureSessionPreset640x480
        
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
            self.capturedImage.contentMode = .ScaleAspectFit
            self.capturedImage.image = chosenImage
            
            self.cropAndSend(chosenImage)
            //self.sendImagePOST(chosenImage)
        })
    }
    
    func stateChanged() {
        self.cropImg1.hidden = true
        self.cropImg2.hidden = true
        self.cropImg3.hidden = true
        self.cropImg4.hidden = true
        
        switch self.searchSetting {
        case .Object:
            self.searchSetting = .Color
            self.outputTextAndVoice("Color mode", speechRate :0.008, textEnable : true)
        case .Color:
            self.searchSetting = .Currency
            self.outputTextAndVoice("Currency mode", speechRate :0.008, textEnable : true)
        case .Currency:
            self.searchSetting = .Live
            self.outputTextAndVoice("LiveStream mode", speechRate :0.008, textEnable : true)
        case .Live:
            self.searchSetting = .Test
            self.outputTextAndVoice("Test mode", speechRate :0.008, textEnable : true)
            self.cropImg1.hidden = false
            self.cropImg2.hidden = false
            self.cropImg3.hidden = false
            self.cropImg4.hidden = false
        case .Test:
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
                        
                        //UIImageOrientationUp,            // default orientation
                        //UIImageOrientationDown,          // 180 deg rotation
                        //UIImageOrientationLeft,          // 90 deg CCW
                        //UIImageOrientationRight,         // 90 deg CW
                        //UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
                        //UIImageOrientationDownMirrored,  // horizontal flip
                        //UIImageOrientationLeftMirrored,  // vertical flip
                        //UIImageOrientationRightMirrored, // vertical flip
                        var myimage = UIImage(CGImage: cgImageRef, scale: 1, orientation: UIImageOrientation.Right)
                        
                        self.capturedImage.image = myimage
                        
                        self.cropAndSend(myimage)
                        //self.sendImagePOST(myimage) // send image to the server
                        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                    }
                })
            }
            
        }
    }
    
    func cropAndSend(myimage : UIImage!) {
        
        // Create rectangles
        //let croprect1 : CGRect = CGRectMake(0, 0, (myimage.size.width/2), (myimage.size.height/2))
        //let croprect2 : CGRect = CGRectMake(myimage.size.width/2, 0, (myimage.size.width/2), (myimage.size.height/2))
        //let croprect3 : CGRect = CGRectMake(0, myimage.size.height/2 , (myimage.size.width/2), (myimage.size.height/2))
        //let croprect4 : CGRect = CGRectMake(myimage.size.width/2, myimage.size.height/2, (myimage.size.width/2), (myimage.size.height/2))
        
        // Create rectangles
        let croprect1 : CGRect = CGRectMake(0, 0, (myimage.size.width/2), (myimage.size.height))
        let croprect2 : CGRect = CGRectMake(myimage.size.width/2, 0, (myimage.size.width/2), (myimage.size.height))
        let croprect3 : CGRect = CGRectMake(0, myimage.size.height/2 , (myimage.size.width), (myimage.size.height/2))
        let croprect4 : CGRect = CGRectMake(0, myimage.size.height/2, (myimage.size.width), (myimage.size.height/2))
        
        // Create rectangles
        //let croprect1 : CGRect = CGRectMake((myimage.size.width/6)                       , (myimage.size.height/6)                         , (myimage.size.width/3), (myimage.size.height/3))
        //let croprect2 : CGRect = CGRectMake((myimage.size.width/2)-(myimage.size.width/6), (myimage.size.height/6)                         , (myimage.size.width/3), (myimage.size.height/3))
        //let croprect3 : CGRect = CGRectMake((myimage.size.width/6)                       , (myimage.size.height/2)-(myimage.size.height/6) , (myimage.size.width/3), (myimage.size.height/3))
        //let croprect4 : CGRect = CGRectMake((myimage.size.width/2)-(myimage.size.width/6), (myimage.size.height/2)-(myimage.size.height/6) , (myimage.size.width/3), (myimage.size.height/3))
        
        
        // Draw new image in current graphics context
        let imageRef1 : CGImageRef = CGImageCreateWithImageInRect(myimage.CGImage, croprect1)
        let imageRef2 : CGImageRef = CGImageCreateWithImageInRect(myimage.CGImage, croprect2)
        let imageRef3 : CGImageRef = CGImageCreateWithImageInRect(myimage.CGImage, croprect3)
        let imageRef4 : CGImageRef = CGImageCreateWithImageInRect(myimage.CGImage, croprect4)
        // Create new cropped UIImage
        let croppedImage1 : UIImage = UIImage(CGImage: imageRef1)!
        let croppedImage2 : UIImage = UIImage(CGImage: imageRef2)!
        let croppedImage3 : UIImage = UIImage(CGImage: imageRef3)!
        let croppedImage4 : UIImage = UIImage(CGImage: imageRef4)!
        
        self.cropImg1.contentMode = .ScaleAspectFit
        self.cropImg1.image = croppedImage1
        self.cropImg2.contentMode = .ScaleAspectFit
        self.cropImg2.image = croppedImage2
        self.cropImg3.contentMode = .ScaleAspectFit
        self.cropImg3.image = croppedImage3
        self.cropImg4.contentMode = .ScaleAspectFit
        self.cropImg4.image = croppedImage4
       
        self.cropCount = 0
        self.myResultArray = []
        
        self.sendImagePOST(myimage)
        //if self.searchSetting == .Test {
        //    self.sendImagePOST(croppedImage1)
        //    self.sendImagePOST(croppedImage2)
        //    self.sendImagePOST(croppedImage3)
        //    self.sendImagePOST(croppedImage4)
        //}
    }
    
    
    let manager = AFHTTPRequestOperationManager()
    func sendImagePOST(myimage : UIImage!){
        self.outputTextAndVoice("One second please...", speechRate :0.1)
        self.myTextLabel.text = "One second please..."
        self.startAVPLayer("StartAudio")
        
        //var imageData = UIImagePNGRepresentation(myimage)
        var imageData = UIImageJPEGRepresentation(myimage, 1.0) //max=1.0
        if imageData != nil{
            //let postURL = "http://requestb.in/powu8hpo"
            //let postURL = "http://molestdepressed.corp.gq1.yahoo.com:8000/api2"
            let postURL = "http://molestdepressed.corp.gq1.yahoo.com:8000/api"
            //let postURL = "http://tradingshading.corp.gq1.yahoo.com:8000/api"
            
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
                    
                    ++self.cropCount
                    self.myResultArray += self.convToEnumArray(response)
                    //if self.searchSetting == .Test {
                    //    if self.cropCount == 5 {
                    //        self.outputResult()
                    //    }
                    //}else{
                         self.outputResult()
                    //}
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
    
    func convToEnumArray(response: AnyObject) -> [(name: String, value: Float)] {
        var myArray:[(name: String, value: Float)] = []
        if let receiver = response as? NSDictionary {
            var d = receiver as Dictionary
            if d.count > 0 {
                for (autotag, numbers) in d {
                    myArray += [(name: autotag as String, value: numbers as Float)]
                }
                myArray.sort { $0.0 == $1.0 ?  $0.0 > $1.0 : $0.1 > $1.1 }
            }
        }  else if let receiver = response as? NSArray {
            var d = receiver as NSArray
            for element in d {
                myArray += [(name: element[0]  as String, value: element[1]  as Float)]
            }
            myArray.sort { $0.0 == $1.0 ?  $0.0 > $1.0 : $0.1 > $1.1 }
        } else {
            println("Bad Dicionary or JSON.")
            self.outputTextAndVoice("Bad Dicionary or JSON.", speechRate :0.06)
                
        }
        println(self.cropCount)
        println(myArray)
        println("========================================")
        return myArray
    }
    func colorOrNot(inputString: String) -> Bool {
        if self.colorString.rangeOfString(" "+inputString+" ") != nil{
            return  true
        }else{
            return false
        }
    }
    
    
    //* * * Voic and text Output functions * * *
    func outputResult(){
        var myArray = self.myResultArray
        myArray.sort { $0.0 == $1.0 ?  $0.0 > $1.0 : $0.1 > $1.1 }
        myArray = self.removeDuplicates(myArray)
        println("__________________________________________________________________________________________________________")
        println(" ")
        println(myArray)
        println(" ")
        switch self.searchSetting {
            case .Object:
                self.objectOut(myArray)
            case .Color:
                self.colorOut(myArray)
            case .Currency:
                self.currencyOut(myArray)
            case .Live:
                self.liveOut(myArray)
            case .Test:
                self.testOut(myArray)
            default:
                self.objectOut(myArray)
                break
        }
    }
    func removeDuplicates(myArray: [(name: String, value: Float)]) -> [(name: String, value: Float)] {
        var filter = Dictionary<String,Int>()
        var len = myArray.count
        var strArray = myArray
        for var index = 0; index < len ; ++index {
            var value = strArray[index]
            if (filter[value.name] != nil) {
                strArray.removeAtIndex(index--)
                len--
            }else{
                filter[value.name] = 1
            }
        }
        return strArray
    }
    
    func objectOut(myArray: [(name: String, value: Float)]){
        var i = 0
        let startString = "I see "
        var outputString = startString
        for myTupels in myArray{
            if (self.exceptionString.rangeOfString(" "+myTupels.name+" ")==nil) && (self.colorOrNot(myTupels.name)==false){
                i++
                if i > 2 {
                    outputString += "and " + myTupels.name
                    break
                }
                outputString += myTupels.name + ", "
            }
        }
        if outputString != startString {
            self.outputTextAndVoice(outputString, speechRate :0.06)
        } else {
            startAVPLayer("NotFoundAudio")
            self.outputTextAndVoice("Try again.", speechRate :0.06)
        }

    }
    func colorOut(myArray: [(name: String, value: Float)]){
        var i = 0
        let startString = "I see the color "
        var outputString = startString
        for myTupels in myArray{
            if (self.colorOrNot(myTupels.name)==true){
                i++
                if i > 2 {
                    outputString += "and the color " + myTupels.name
                    break
                }
                outputString += myTupels.name + ", "
            }
        }
        if outputString != startString {
            self.outputTextAndVoice(outputString, speechRate :0.06)
        } else {
            startAVPLayer("NotFoundAudio")
            self.outputTextAndVoice("Try again.", speechRate :0.06)
        }
    }
    func currencyOut(myArray: [(name: String, value: Float)]){
        self.outputTextAndVoice("Currency mode is not available", speechRate :0.06)
    }
    func liveOut(myArray: [(name: String, value: Float)]){
        var i = 0
        let startString = ""
        var outputString = startString
        for myTupels in myArray{
            if ((self.exceptionString.rangeOfString(" "+myTupels.name+" ")==nil) || (myArray.count<4)) {
                i++
                if i > 2 {
                    outputString += " " + myTupels.name
                    break
                }
                outputString += myTupels.name + ", "
            }
        }
        if outputString != startString {
            self.outputTextAndVoice(outputString, speechRate :0.06)
        }
        self.takePhoto()
        
    }
    func testOut(myArray: [(name: String, value: Float)]){
        var i = 0
        let startString = ""
        var outputString = startString
        for myTupels in myArray{
            i++
            outputString += myTupels.name + ", "
            if myArray.count==5 { break }
        }
        if outputString != startString {
            self.outputTextAndVoice(outputString, speechRate :0.06)
        } else {
            startAVPLayer("NotFoundAudio")
            self.outputTextAndVoice("Try again.", speechRate :0.06)
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

    //* * * Sound * * *
    var myWaitingSound = AVAudioPlayer()
    func waitingSoundaa(){
        
        let filePath:NSURL = NSURL(fileURLWithPath: "Users/pouria/Desktop/Apps/sounds/Alerts/hello.m4r")!
        println(filePath)
        var er:NSError?
        let audioPlayer:AVAudioPlayer = AVAudioPlayer(contentsOfURL: filePath, error: &er)
        
        
        if (er != nil) {
            println("There was an error: \(er)")
        } else {
            println("playing...")
            audioPlayer.play()
            while audioPlayer.playing{
                println("playing")
            }
        }

    }
    
    //* * * The SSound player * * *
    //The player instance needs to be an instance variable. Otherwise it will disappear before playing.
    var avPlayer:AVAudioPlayer!
    func startAVPLayer(myAudio : String) {
        //var error: NSError?
        //let fileURL:NSURL = NSBundle.mainBundle().URLForResource("hello", withExtension: "m4r")
        /*var fileURL:NSURL = NSURL(fileURLWithPath: "Users/pouria/Desktop/Apps/sounds/Alerts/hello.m4r")!
        switch myAudio {
            case "StartAudio":
                fileURL = NSURL(fileURLWithPath: "Users/pouria/Desktop/Apps/sounds/Alerts/hello.m4r")!
            case "NotFoundAudio":
                fileURL = NSURL(fileURLWithPath: "Users/pouria/Desktop/Apps/sounds/Alerts/synth.m4r")!
            default:
                fileURL = NSURL(fileURLWithPath: "Users/pouria/Desktop/Apps/sounds/Alerts/hello.m4r")!
                break
        }*/
        
        
        //The player must be a field. Otherwise it will be released before playing starts.
        //self.avPlayer = AVAudioPlayer(contentsOfURL: fileURL, error: &error)
        //if avPlayer == nil {
        //    if let e = error { println(e.localizedDescription) }
        //}else {
        //    println("playing \(fileURL)")
        //    // avPlayer.delegate = self
        //    avPlayer.prepareToPlay()
        //    avPlayer.volume = 1.0
        //    avPlayer.play()
       // }
    }
    func stopAVPLayer() {
        if avPlayer.playing { avPlayer.stop() }
    }
    func toggleAVPlayer() {
        if avPlayer.playing {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }

}

