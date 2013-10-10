//
//  RACameraController.h
//
//  Version 0.3, October 10th, 2013
//
//  Created by Andreas de Reggi on 07. 10. 2013.
//  Copyright (c) 2013 Nollie Apps.
//
//  Get the latest version from here:
//
//  https://github.com/Reggian/RACameraController
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import <UIKit/UIKit.h>

@interface RACameraController : NSObject

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

@property (nonatomic, readonly) BOOL isCameraAvailable;

- (void)takePicture;
- (void)dismissCamera;
- (void)setCameraDevice:(UIImagePickerControllerCameraDevice)cameraDevice;
- (void)setCameraFlashMode:(UIImagePickerControllerCameraFlashMode)cameraFlashMode;

- (void)presentCameraAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)dismissCameraAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)setImagePickerControllerDelegate:(id<UIImagePickerControllerDelegate,UINavigationControllerDelegate>)delegate;

@end

@interface RACameraOverlayView : UIView

@property (nonatomic, weak, readonly) RACameraController *cameraController;
@property (nonatomic) CGAffineTransform cameraViewTransform;

- (instancetype)initWithCameraController:(RACameraController *)controller;

@end

@interface RAFlashView : UIView

@property (nonatomic, weak, readonly) RACameraOverlayView *cameraOverlayView;

- (instancetype)initWithCameraOverlayView:(RACameraOverlayView *)cameraOverlayView;

- (void)setOrientation:(UIInterfaceOrientation)orientation;

@end
