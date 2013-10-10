RACameraController
==================

Clone of UIImagePickerController camera controls without confirmation screen.
Both iOS 7 and iOS 6 design implemented.

ARC Compatibility
-----------------

RACameraController requires ARC.

Installation and Usage
------------

To use RACameraController, just drag the RACameraController folder into your project.

See the CameraControllerExample app for usage.


Properties and Methods
----------------------

**RACameraController has the following property:**

  @property (nonatomic, readonly) BOOL isCameraAvailable;

Returns YES if the camera is supported on the device and NO if it is not.

**RACameraController has one initialisation method:**

  - (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

Returns initialised RACameraController object. The parameter `rootViewController` should be the main `UIViewController` that wil present the 'UIImagePickerController'.

**Setting the delegate:**

  - (void)setImagePickerControllerDelegate:(id<UIImagePickerControllerDelegate,UINavigationControllerDelegate>)delegate;

The delegate should implement the default `UIImagePickerControllerDelegate` methods.

**Presenting and dismissing the camera:**

  - (void)presentCameraAnimated:(BOOL)animated completion:(void (^)(void))completion;
  - (void)dismissCameraAnimated:(BOOL)animated completion:(void (^)(void))completion;

This two methods will present/dismiss the camera calling the completion block on completion.


