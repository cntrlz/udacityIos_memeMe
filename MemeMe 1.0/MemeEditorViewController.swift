//
//  MemeEditorViewController.swift
//  MemeMe 1.0
//
//  Created by benchmark on 8/31/16.
//  Copyright © 2016 Viktor Lantos. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

	@IBOutlet weak var previewImageView: UIImageView!
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var cameraButton: UIBarButtonItem!
	@IBOutlet weak var textFieldTop: UITextField!
	@IBOutlet weak var textFieldBottom: UITextField!
	@IBOutlet weak var shareButton: UIBarButtonItem!
	
	enum DefaultText : String {
		case Top = "TOP"
		case Bottom = "BOTTOM"
	}
	
	struct Meme {
		let topText: String
		let bottomText: String
		let originalImage : UIImage
		let memedImage : UIImage
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Check to see if our device has a camera. If it does not support one, disable our camera button
		if !UIImagePickerController.isSourceTypeAvailable(.Camera){
			cameraButton.enabled = false
		}
		
		// Register our UIImageView for taps so we can dismiss the keyboard in a more intuitive fashion
		let imageTap = UITapGestureRecognizer(target: self, action: #selector(MemeEditorViewController.dismissKeyboard))
		previewImageView.addGestureRecognizer(imageTap)
		previewImageView.userInteractionEnabled = true
		
		setupTextFields()
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		subscribeToKeyboardNotifications()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		unsubscribeFromKeyboardNotifications()
	}
	
	func setupTextFields() {
		let style = NSMutableParagraphStyle()
		style.alignment = .Center
		
		let memeTextAttributes = [
			NSStrokeColorAttributeName : UIColor.blackColor(),
			NSForegroundColorAttributeName : UIColor.whiteColor(),
			NSFontAttributeName : UIFont(name: "Impact", size: 40)!,
			NSStrokeWidthAttributeName : -4.0,
			NSParagraphStyleAttributeName : style
		]
		
		textFieldTop.defaultTextAttributes = memeTextAttributes
		textFieldBottom.defaultTextAttributes = memeTextAttributes
		textFieldTop.autocorrectionType = UITextAutocorrectionType.No
		textFieldBottom.autocorrectionType = UITextAutocorrectionType.No
	}

    // MARK: - User Actions
	@IBAction func showCamera(sender: AnyObject) {
		let imagePicker = UIImagePickerController()
		imagePicker.delegate = self
		imagePicker.sourceType = .Camera
		imagePicker.allowsEditing = true
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func showAlbum(sender: AnyObject) {
		let imagePicker = UIImagePickerController()
		imagePicker.delegate = self
		imagePicker.sourceType = .PhotoLibrary
		imagePicker.allowsEditing = true
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func share(sender: AnyObject) {
		if (previewImageView.image != nil) {
			let meme = makeMeme()
			let activityController = UIActivityViewController(activityItems: [meme.memedImage], applicationActivities: nil)
			activityController.completionWithItemsHandler = { activity, success, items, error in
				if success {
					self.save(meme)
				}
			}
			presentViewController(activityController, animated: true, completion:nil)

		} else {
			let controller = UIAlertController()
			controller.title = "No Image to Share"
			controller.message = "Please select an image to share"
			let dismiss = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
				self.dismissViewControllerAnimated(true, completion: nil)
			})
			controller.addAction(dismiss)
			
			self .presentViewController(controller, animated: true, completion: nil)
		}
	}
	
	@IBAction func cancel(sender: AnyObject) {
		view.endEditing(true)
		previewImageView.image = nil
		shareButton.enabled = false
		textFieldTop.text = DefaultText.Top.rawValue
		textFieldBottom.text = DefaultText.Bottom.rawValue
	}
	
	// MARK: - Images and Saving
	func makeMeme() -> Meme{
		let memedImage : UIImage = generateMemedImage()
		let meme = Meme(topText: textFieldTop.text!, bottomText:textFieldBottom.text!, originalImage: previewImageView.image!, memedImage: memedImage)
		return meme
	}
	
	func save(meme: Meme) {
		// Implemented at a later time
	}
	
	func generateMemedImage() -> UIImage {
		toolbar.hidden = true
		navigationController?.navigationBarHidden = true
		
		// Render view to an image
		UIGraphicsBeginImageContext(self.view.frame.size)
		view.drawViewHierarchyInRect(self.view.frame,
		                             afterScreenUpdates: true)
		let memedImage : UIImage =
			UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		toolbar.hidden = false
		navigationController?.navigationBarHidden = false
		
		return memedImage
	}
	
	// MARK: - Text Field Delegate Methods
	func textFieldDidBeginEditing(textField: UITextField) {
		if textField.text == DefaultText.Top.rawValue || textField.text == DefaultText.Bottom.rawValue {
			textField.text = ""
		}
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if textField.text == "" {
			textField.text = textField == textFieldTop ? DefaultText.Top.rawValue : DefaultText.Bottom.rawValue
		}
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	// MARK: - Image Picker Delegate Methods
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
			previewImageView.image = image
			shareButton.enabled = true
		}
		
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - Keyboard Management
	func subscribeToKeyboardNotifications() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MemeEditorViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MemeEditorViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
	}
	
	func unsubscribeFromKeyboardNotifications() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name:
			UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name:
			UIKeyboardWillHideNotification, object: nil)
	}
	
	func keyboardWillShow(notification: NSNotification) {
		if textFieldBottom.isFirstResponder(){
			view.frame.origin.y -= getKeyboardHeight(notification)
		}
	}
	
	func keyboardWillHide(notification: NSNotification) {
		view.frame.origin.y = 0
	}
	
	func getKeyboardHeight(notification: NSNotification) -> CGFloat {
		let userInfo = notification.userInfo
		let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
		return keyboardSize.CGRectValue().height
	}
	
	func dismissKeyboard() {
		view.endEditing(true)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
