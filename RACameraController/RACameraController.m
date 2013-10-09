//
//  RACameraController.m
//
//  Version 0.1, October 7th, 2013
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

#import "RACameraController.h"

//--------------------------------------------------------------------------------------------------------------
#pragma mark - UIImagePickerController RAExtension -
//--------------------------------------------------------------------------------------------------------------

@implementation UIImagePickerController (RAExtension)
- (BOOL)prefersStatusBarHidden
{
	return YES;
}
- (UIViewController *)childViewControllerForStatusBarHidden
{
	return nil;
}
@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RACameraOverlayView Subclasses -
//--------------------------------------------------------------------------------------------------------------

@interface RACameraOverlayView7 : RACameraOverlayView
@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RACameraController -
//--------------------------------------------------------------------------------------------------------------

@interface RACameraController ()
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, weak) UIViewController *rootViewController;
@end

@implementation RACameraController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self)
	{
		self.rootViewController = rootViewController;
		_isCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
		if (_isCameraAvailable)
		{			
			self.imagePickerController = [[UIImagePickerController alloc] init];
			[_imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
			[_imagePickerController setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
			
			[self setupCameraOverlay];
		}
		else
		{
			NSLog(@"WARNING RACameraController : Camera source not available.");
		}
    }
    return self;
}

- (void)setupCameraOverlay
{
	RACameraOverlayView *cameraOverlayView = [[RACameraOverlayView7 alloc] initWithCameraController:self];

	[_imagePickerController setShowsCameraControls:NO];
	[_imagePickerController setCameraOverlayView:cameraOverlayView];
	[_imagePickerController setCameraViewTransform:cameraOverlayView.cameraViewTransform];
}

- (void)takePicture
{
	[_imagePickerController takePicture];
}
- (void)dismissCamera
{
	if ([_imagePickerController.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)])
	{
		[_imagePickerController.delegate imagePickerControllerDidCancel:_imagePickerController];
	}
	else
	{
		[self dismissCameraAnimated:NO completion:NULL];
	}
}
- (void)setCameraDevice:(UIImagePickerControllerCameraDevice)cameraDevice
{
	if ([UIImagePickerController isCameraDeviceAvailable:cameraDevice])
	{
		[_imagePickerController setCameraDevice:cameraDevice];
	}
	else
	{
		NSLog(@"WARNING RACameraController : Camera device not available.");
	}
}
- (void)setCameraFlashMode:(UIImagePickerControllerCameraFlashMode)cameraFlashMode
{
	if ([UIImagePickerController isFlashAvailableForCameraDevice:_imagePickerController.cameraDevice])
	{
		[_imagePickerController setCameraFlashMode:cameraFlashMode];
	}
	else
	{
		NSLog(@"WARNING RACameraController : Flash mode not available for current camera device.");
	}
}

- (void)presentCameraAnimated:(BOOL)animated completion:(void (^)(void))completion
{
	[_rootViewController presentViewController:_imagePickerController animated:animated completion:completion];
}

- (void)dismissCameraAnimated:(BOOL)animated completion:(void (^)(void))completion
{
	if ([_imagePickerController isEqual:_rootViewController.presentedViewController])
	{
		[_rootViewController dismissViewControllerAnimated:animated completion:completion];
	}
	else
	{
		NSLog(@"WARNING RACameraController : UIImagePickerController is not presented.");
	}
}

- (void)setImagePickerControllerDelegate:(id<UIImagePickerControllerDelegate,UINavigationControllerDelegate>)delegate
{
	[_imagePickerController setDelegate:delegate];
}

@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RACameraOverlayView -
//--------------------------------------------------------------------------------------------------------------

@implementation RACameraOverlayView
{
	UIInterfaceOrientation _interfaceOrientation;
}

- (instancetype)initWithCameraController:(RACameraController *)controller
{
	CGRect frame = [[UIScreen mainScreen] bounds];
    self = [super initWithFrame:frame];
    if (self)
	{
		_cameraController = controller;
		[self setTintColor:[UIColor whiteColor]];
        [self setup];
				
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(deviceDidRotate:)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup{}

- (void)deviceDidRotate:(NSNotification *)notification
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	UIInterfaceOrientation interfaceOrientation = _interfaceOrientation;
	switch (deviceOrientation)
	{
		case UIDeviceOrientationPortrait:
			interfaceOrientation = UIInterfaceOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			interfaceOrientation = UIInterfaceOrientationLandscapeRight;
			break;
		default:
			break;
	}
	if (interfaceOrientation != _interfaceOrientation)
	{
		_interfaceOrientation = interfaceOrientation;
		[self interfaceDidChangeOrientation:_interfaceOrientation];
	}
}

- (void)interfaceDidChangeOrientation:(UIInterfaceOrientation)orientation{}

@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RACameraOverlayView7
//--------------------------------------------------------------------------------------------------------------

@implementation RACameraOverlayView7
{
	UIButton *_cancelButton;
	UIButton *_photoButton;
	UIButton *_switchButton;
	RAFlashView *_flashView;
}

- (void)setup
{
	if (self.bounds.size.height == 568.0)
	{
		[self setCameraViewTransform:CGAffineTransformMakeTranslation(0.0, 60.0)];
	}
	
	UIImageView *bottomBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height-80.0, 320.0, 80.0)];
	[bottomBackground setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];
	[bottomBackground setContentMode:UIViewContentModeCenter];
	[bottomBackground setImage:[UIImage imageNamed:@"RACameraController.bundle/RACC_shutter_bkg"]];
	[self addSubview:bottomBackground];
	
	_cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[_cancelButton setFrame:CGRectMake(0.0, 0.0, 100.0, 60.0)];
	[_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
	[_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
	[_cancelButton addTarget:self.cameraController action:@selector(dismissCamera) forControlEvents:UIControlEventTouchUpInside];
	[_cancelButton setCenter:CGPointMake(40.0, self.bounds.size.height-40.0)];
	[self addSubview:_cancelButton];
	
	_photoButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[_photoButton setFrame:CGRectMake(0.0, 0.0, 66.0, 66.0)];
	[_photoButton setImage:[UIImage imageNamed:@"RACameraController.bundle/RACC_shutter"] forState:UIControlStateNormal];
	[_photoButton addTarget:self.cameraController action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
	[_photoButton setCenter:CGPointMake(160.0, self.bounds.size.height-40.0)];
	[self addSubview:_photoButton];
	
	if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
	{
		_switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
		[_switchButton setFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
		[_switchButton setImage:[UIImage imageNamed:@"RACameraController.bundle/RACC_switch"] forState:UIControlStateNormal];
		[_switchButton addTarget:self action:@selector(switchCameraDevice) forControlEvents:UIControlEventTouchUpInside];
		[_switchButton setCenter:CGPointMake(292.0, 22.0)];
		[self addSubview:_switchButton];
	}
	
	if ([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear])
	{
		_flashView = [[RAFlashView alloc] initWithCameraOverlayView:self];
		[self addSubview:_flashView];
	}
}

- (void)switchCameraDevice
{
	UIImagePickerControllerCameraDevice device;
	switch (self.cameraController.imagePickerController.cameraDevice)
	{
		case UIImagePickerControllerCameraDeviceFront:
			device = UIImagePickerControllerCameraDeviceRear;
			break;
		case UIImagePickerControllerCameraDeviceRear:
			device = UIImagePickerControllerCameraDeviceFront;
			break;
	}
	[self.cameraController setCameraDevice:device];
	CGFloat alpha = ([UIImagePickerController isFlashAvailableForCameraDevice:device]?1.0:0.0);
	[UIView animateWithDuration:0.2 animations:^{
		[_flashView setAlpha:alpha];
	}];
}

- (void)interfaceDidChangeOrientation:(UIInterfaceOrientation)orientation
{
	double angle;
	switch (orientation)
	{
		case UIInterfaceOrientationPortrait:
			angle = 0.0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = 0.5*M_PI;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = 1.5*M_PI;
			break;
	}
	[UIView animateWithDuration:0.2 animations:^{
		[_switchButton setTransform:CGAffineTransformMakeRotation(angle)];
	}];
	[UIView animateWithDuration:0.1
					 animations:^{
						 [_flashView setAlpha:0.0];
					 }
					 completion:^(BOOL finished) {
						 [_flashView setOrientation:orientation];
						 [UIView animateWithDuration:1.0 animations:^{
							 [_flashView setAlpha:1.0];
						 }];
					 }];
}

@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RAFlashView -
//--------------------------------------------------------------------------------------------------------------

typedef enum
{
	RAFlashModeAuto = 0,
	RAFlashModeOn,
	RAFlashModeOff,
	RAFlashModes
}
RAFlashMode;

CGRect RAResizedFrameWithFactor(CGRect frame, CGFloat factor)
{
	CGSize fsize = CGSizeMake(frame.size.width*factor, frame.size.height*factor);
	return CGRectMake(frame.origin.x - (fsize.width - frame.size.width)/2, frame.origin.y - (fsize.height - frame.size.height)/2, fsize.width, fsize.height);
}

RAFlashMode RAFlashModeFromLocation(CGPoint location)
{
	if (location.x > 105.0)
	{
		return RAFlashModeOff;
	}
	else if (location.x > 60.0)
	{
		return RAFlashModeOn;
	}
	else
	{
		return RAFlashModeAuto;
	}
}

@implementation RAFlashView
{
	UIImageView *_flashImage;
	UILabel *_modeLabel[RAFlashModes];
	CGAffineTransform _orientationTransform[RAFlashModes+1];
	
	RAFlashMode _flashMode;
	RAFlashMode _hlFlashMode;
	CGRect _hitFrame;
	BOOL _highlighted;
	BOOL _expanded;
	
	NSTimer *_collapseTimer;
	
	UIInterfaceOrientation _orientation;
}

- (instancetype)initWithCameraOverlayView:(RACameraOverlayView *)cameraOverlayView
{
	CGRect frame = CGRectMake(0.0, 0.0, 80.0, 44.0);
    self = [super initWithFrame:frame];
    if (self)
	{
		_cameraOverlayView = cameraOverlayView;

		_flashImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RACameraController.bundle/RACC_flash"]];
		[_flashImage setCenter:CGPointMake(16.0, 24.0)];
		[self addSubview:_flashImage];
		_modeLabel[RAFlashModeOff] = [self modeLabelWithText:@"O f f"];
		[_modeLabel[RAFlashModeOff] setAlpha:0.0];
		[self addSubview:_modeLabel[RAFlashModeOff]];
		_modeLabel[RAFlashModeOn] = [self modeLabelWithText:@"O n"];
		[_modeLabel[RAFlashModeOn] setAlpha:0.0];
		[self addSubview:_modeLabel[RAFlashModeOn]];
		_modeLabel[RAFlashModeAuto] = [self modeLabelWithText:@"A u t o"];
		[self addSubview:_modeLabel[RAFlashModeAuto]];
		
		_orientationTransform[RAFlashModeAuto] = CGAffineTransformIdentity;
		_orientationTransform[RAFlashModeOn] = CGAffineTransformIdentity;
		_orientationTransform[RAFlashModeOff] = CGAffineTransformIdentity;
		_orientationTransform[RAFlashModes] = CGAffineTransformIdentity;
	}
    return self;
}

- (UILabel *)modeLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(28.0, 17.0, 50.0, 11.0)];
//	[label setFont:[UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:11]];
	[label setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:11]];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextColor:[UIColor whiteColor]];
	[label setText:text];
	[label sizeToFit];
	return label;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	_hitFrame = RAResizedFrameWithFactor(frame, 2.0);
}

- (void)setOrientation:(UIInterfaceOrientation)orientation
{
	_orientation = orientation;

	double angle;
	switch (_orientation)
	{
		case UIInterfaceOrientationPortrait:
			angle = 0.0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = 0.5*M_PI;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = 1.5*M_PI;
			break;
	}
	
	_orientationTransform[RAFlashModeAuto] = CGAffineTransformMakeRotation(angle);
	_orientationTransform[RAFlashModeOn] = CGAffineTransformMakeRotation(angle);
	_orientationTransform[RAFlashModeOff] = CGAffineTransformMakeRotation(angle);
	_orientationTransform[RAFlashModes] = CGAffineTransformMakeRotation(angle);
	
	[_modeLabel[RAFlashModeAuto] setTransform:_orientationTransform[RAFlashModeAuto]];
	[_modeLabel[RAFlashModeOn] setTransform:_orientationTransform[RAFlashModeOn]];
	[_modeLabel[RAFlashModeOff] setTransform:_orientationTransform[RAFlashModeOff]];
	[_flashImage setTransform:_orientationTransform[RAFlashModes]];
}

- (void)setHighlighted:(BOOL)highlighted
{
	if (_highlighted != highlighted)
	{
		_highlighted = highlighted;
		
		CGFloat alpha = (highlighted?0.2:1.0);
		[UIView animateWithDuration:0.2
							  delay:0.0
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 [_flashImage setAlpha:alpha];
							 [_modeLabel[_flashMode] setAlpha:alpha];
						 }
						 completion:NULL];
	}
}

- (void)setHighlightedForExpandedFlashMode:(RAFlashMode)flashMode
{
	[UIView animateWithDuration:0.2
						  delay:0.0
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 for (RAFlashMode fm = 0; fm < RAFlashModes; fm++)
						 {
							 [_modeLabel[fm] setAlpha:(fm==flashMode?0.2:1.0)];
						 }
					 }
					 completion:NULL];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!_expanded)
	{
		[self setHighlighted:YES];
	}
	else
	{
		CGPoint location = [[touches anyObject] locationInView:self];
		_hlFlashMode = RAFlashModeFromLocation(location);
		[self setHighlightedForExpandedFlashMode:_hlFlashMode];
	}
	
	if ([_collapseTimer isValid])
	{
		[_collapseTimer invalidate];
		_collapseTimer = nil;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location = [[touches anyObject] locationInView:self];
	BOOL highlighted = CGRectContainsPoint(_hitFrame, location);
	
	if (!_expanded)
	{
		[self setHighlighted:highlighted];
	}
	else
	{
		RAFlashMode flashMode = (highlighted?RAFlashModeFromLocation(location):RAFlashModes);
		if (flashMode != _hlFlashMode)
		{
			_hlFlashMode = (highlighted?flashMode:RAFlashModes);
			[self setHighlightedForExpandedFlashMode:_hlFlashMode];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location = [[touches anyObject] locationInView:self];
	
	if (!_expanded)
	{
		[self setHighlighted:NO];
		
		[self expand];
		
		_collapseTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(collapse) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:_collapseTimer forMode:NSRunLoopCommonModes];
	}
	else if (CGRectContainsPoint(_hitFrame, location))
	{
		_flashMode = RAFlashModeFromLocation(location);
		[self collapseWithFlashMode:_flashMode];
		
		UIImagePickerControllerCameraFlashMode cameraFlashMode;
		switch (_flashMode)
		{
			case RAFlashModeAuto:
				cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
				break;
			case RAFlashModeOn:
				cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
				break;
			case RAFlashModeOff:
				cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
				break;
			default:
				cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
				break;
		}
		[_cameraOverlayView.cameraController setCameraFlashMode:cameraFlashMode];
	}
	else
	{
		[self setHighlighted:NO];
		
		_collapseTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(collapse) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:_collapseTimer forMode:NSRunLoopCommonModes];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self collapse];
}

- (void)expand
{
	_expanded = YES;
	[self setFrame:CGRectMake(0.0, 0.0, 160.0, 44.0)];
	
	CGAffineTransform tFlashModeOn = CGAffineTransformMakeTranslation(60.0, 0.0);
	tFlashModeOn = CGAffineTransformConcat(_orientationTransform[RAFlashModeOn],tFlashModeOn);
	CGAffineTransform tFlashModeOff = CGAffineTransformMakeTranslation(105.0, 0.0);
	tFlashModeOff = CGAffineTransformConcat(_orientationTransform[RAFlashModeOff],tFlashModeOff);
	
	[UIView animateWithDuration:0.2
					 animations:^{
						 [_modeLabel[RAFlashModeAuto] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOn] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOff] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOn] setTransform:tFlashModeOn];
						 [_modeLabel[RAFlashModeOff] setTransform:tFlashModeOff];
					 }];
}

- (void)collapse
{
	[self collapseWithFlashMode:_flashMode];
}

- (void)collapseWithFlashMode:(RAFlashMode)flashMode
{
	_expanded = NO;
	[self setFrame:CGRectMake(0.0, 0.0, 80.0, 44.0)];

	[UIView animateWithDuration:0.2 animations:^{
		for (RAFlashMode fm = 0; fm < RAFlashModes; fm++)
		{
			[_modeLabel[fm] setAlpha:(fm == flashMode?1.0:0.0)];
		}
		[_modeLabel[RAFlashModeOn] setTransform:_orientationTransform[RAFlashModeOn]];
		[_modeLabel[RAFlashModeOff] setTransform:_orientationTransform[RAFlashModeOff]];
	}];
}

@end
