//
//  RACameraController.m
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

#import "RACameraController.h"

// Macro thanks to yasirmturk
// http://stackoverflow.com/a/5337804
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation UIImage (RAExtension)

+ (UIImage *)RAImageNamed:(NSString *)name
{
	return [UIImage imageNamed:[NSString stringWithFormat:@"RACameraController.bundle/%@",name]];
}

@end

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

@interface RACameraOverlayView6 : RACameraOverlayView
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
	RACameraOverlayView *cameraOverlayView;
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
	{
		cameraOverlayView = [[RACameraOverlayView7 alloc] initWithCameraController:self];
	}
	else
	{
		cameraOverlayView = [[RACameraOverlayView6 alloc] initWithCameraController:self];
	}

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

typedef enum
{
	RAFlashModeAuto = 0,
	RAFlashModeOn,
	RAFlashModeOff,
	RAFlashModes
}
RAFlashMode;

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
		_cameraViewTransform = CGAffineTransformIdentity;
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
	[self setTintColor:[UIColor whiteColor]];
	
	CGFloat screenHeight = self.bounds.size.height;
	
	if (screenHeight == 568.0)
	{
		[self setCameraViewTransform:CGAffineTransformMakeTranslation(0.0, 60.0)];
	}
	else
	{
		UIView *topBackground = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 60.0)];
		[topBackground setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
		[self addSubview:topBackground];
	}

	UIImageView *bottomBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, screenHeight-80.0, 320.0, 80.0)];
	[bottomBackground setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
	[bottomBackground setContentMode:UIViewContentModeCenter];
	[bottomBackground setImage:[UIImage RAImageNamed:@"RACC_shutter_bkg"]];
	[self addSubview:bottomBackground];
	
	_cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[_cancelButton setFrame:CGRectMake(0.0, 0.0, 100.0, 60.0)];
	[_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
	[_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
	[_cancelButton addTarget:self.cameraController action:@selector(dismissCamera) forControlEvents:UIControlEventTouchUpInside];
	[_cancelButton setCenter:CGPointMake(40.0, screenHeight-40.0)];
	[self addSubview:_cancelButton];
	
	_photoButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[_photoButton setFrame:CGRectMake(0.0, 0.0, 66.0, 66.0)];
	[_photoButton setImage:[UIImage RAImageNamed:@"RACC_shutter"] forState:UIControlStateNormal];
	[_photoButton addTarget:self.cameraController action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
	[_photoButton setCenter:CGPointMake(160.0, screenHeight-40.0)];
	[self addSubview:_photoButton];
	
	if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
	{
		_switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
		[_switchButton setFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
		[_switchButton setImage:[UIImage RAImageNamed:@"RACC_switch"] forState:UIControlStateNormal];
		[_switchButton addTarget:self action:@selector(switchCameraDevice) forControlEvents:UIControlEventTouchUpInside];
		[_switchButton setCenter:CGPointMake(292.0,27.0)];
		[self addSubview:_switchButton];
	}
	
	if ([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear])
	{
		_flashView = [[RAFlashView alloc] initWithCameraOverlayView:self];
		[_flashView setCenter:CGPointMake(40.0, 27.0)];
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
#pragma mark - RACameraOverlayView6
//--------------------------------------------------------------------------------------------------------------

@implementation RACameraOverlayView6
{
	UIImageView *_cImageView;
	UIImageView *_xImageView;
	UIImageView *_fImageView;
	UIView *_overlayView;
	UIImage *_flashImage[RAFlashModes];
	UIButton *_switchButton;
	UIButton *_flashButton;
	RAFlashMode _flashMode;
	CGFloat _screenHeight;
	CGFloat _offset;
}

- (void)setup
{
	_screenHeight = [[UIScreen mainScreen] bounds].size.height;
	
	BOOL isR4 = (_screenHeight == 568);
	
	_offset = (isR4 ? 96.0 : 54.0);
	
	_overlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _screenHeight - _offset, 320.0)];
	[_overlayView setCenter:CGPointMake(160.0, (_screenHeight - _offset)/2)];
	[self addSubview:_overlayView];

	UIImageView *bottomBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, _screenHeight - _offset, 320.0, _offset)];
	[bottomBackground setBackgroundColor:[UIColor blackColor]];
	[bottomBackground setImage:[UIImage RAImageNamed:(isR4?@"RACC_6_barR4":@"RACC_6_bar")]];
	[self addSubview:bottomBackground];

	if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
	{
		_switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_switchButton setImage:[UIImage RAImageNamed:@"RACC_6_switch"] forState:UIControlStateNormal];
		[_switchButton addTarget:self action:@selector(switchCameraDevice) forControlEvents:UIControlEventTouchUpInside];
		[_switchButton setFrame:CGRectMake(self.bounds.size.width - 90.0, 10.0, 80.0, 45.0)];
		[_overlayView addSubview:_switchButton];
	}
	
	if ([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear])
	{
		_flashImage[RAFlashModeAuto] = [UIImage RAImageNamed:@"RACC_6_flash_auto"];
		_flashImage[RAFlashModeOn] = [UIImage RAImageNamed:@"RACC_6_flash_on"];
		_flashImage[RAFlashModeOff] = [UIImage RAImageNamed:@"RACC_6_flash_off"];
		_flashMode= RAFlashModeAuto;
		
		_fImageView = [[UIImageView alloc] initWithImage:_flashImage[RAFlashModeAuto]];
		[_fImageView setFrame:(CGRect){{10.0, 10.0}, _flashImage[RAFlashModeAuto].size}];
		[_overlayView addSubview:_fImageView];
		
		_flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_flashButton setFrame:CGRectMake(0.0, 0.0, 54.0, 54.0)];
		[_flashButton setCenter:_fImageView.center];
		[_flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[_overlayView addSubview:_flashButton];
	}
	
	UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[cameraButton addTarget:self.cameraController action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
	if (isR4)
	{
		[cameraButton setImage:[UIImage RAImageNamed:@"RACC_6_shutter_bkgR4"] forState:UIControlStateNormal];
		[cameraButton setImage:[UIImage RAImageNamed:@"RACC_6_shutter_bkg_hlR4"] forState:UIControlStateHighlighted];
		[cameraButton setFrame:CGRectMake(0.0, 0.0, 75, 76)];
	}
	else
	{
		[cameraButton setImage:[UIImage RAImageNamed:@"RACC_6_shutter_bkg"] forState:UIControlStateNormal];
		[cameraButton setImage:[UIImage RAImageNamed:@"RACC_6_shutter_bkg_hl"] forState:UIControlStateHighlighted];
		[cameraButton setFrame:CGRectMake(0.0, 0.0, 100.0, 54.0)];
	}
	[cameraButton setCenter:CGPointMake(160.0, _screenHeight - _offset/2)];
	[self addSubview:cameraButton];
	
	UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[closeButton addTarget:self.cameraController action:@selector(dismissCamera) forControlEvents:UIControlEventTouchUpInside];
	[closeButton setImage:[UIImage RAImageNamed:@"RACC_6_cancel_bkg"] forState:UIControlStateNormal];
	[closeButton setImage:[UIImage RAImageNamed:@"RACC_6_cancel_bkg_hl"] forState:UIControlStateHighlighted];
	[closeButton setFrame:CGRectMake(0.0, 0.0, 54.0, 54.0)];
	[closeButton setCenter:CGPointMake(32.0, _screenHeight - _offset/2)];
	[self addSubview:closeButton];
	
	_cImageView = [[UIImageView alloc] initWithImage:[UIImage RAImageNamed:(isR4?@"RACC_6_shutterR4":@"RACC_6_shutter")]];
	[_cImageView setCenter:cameraButton.center];
	[self addSubview:_cImageView];
	
	_xImageView = [[UIImageView alloc] initWithImage:[UIImage RAImageNamed:@"RACC_6_cancel"]];
	[_xImageView setCenter:closeButton.center];
	[self addSubview:_xImageView];
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
	
	BOOL isFlashAvailable = [UIImagePickerController isFlashAvailableForCameraDevice:device];
	[_flashButton setEnabled:isFlashAvailable];
	CGFloat alpha = (isFlashAvailable?1.0:0.0);
	[UIView animateWithDuration:0.2 animations:^{
		[_fImageView setAlpha:alpha];
	}];
}

- (void)interfaceDidChangeOrientation:(UIInterfaceOrientation)orientation
{
	double angle;
	CGSize size;
	switch (orientation)
	{
		case UIInterfaceOrientationPortrait:
			angle = 0.0;
			size = CGSizeMake(320.0, _screenHeight - _offset);
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			size = CGSizeMake(320.0, _screenHeight - _offset);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = 0.5*M_PI;
			size = CGSizeMake(_screenHeight - _offset, 320.0);
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = 1.5*M_PI;
			size = CGSizeMake(_screenHeight - _offset, 320.0);
			break;
	}
	CGRect switchFrame = _switchButton.frame;
	CGRect bounds = (CGRect){CGPointZero,size};
	
	CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
	switchFrame.origin.x = bounds.size.width - 90.0f;
	
	[UIView animateWithDuration:0.3
					 animations:^{
						 _overlayView.bounds = bounds;
						 _overlayView.transform = transform;
						 _cImageView.transform = transform;
						 _xImageView.transform = transform;
						 _switchButton.frame = switchFrame;
					 }
					 completion:^(BOOL finished) {
						 [UIView animateWithDuration:0.3
										  animations:^{
											  [_switchButton setAlpha:1.0];
											  [_fImageView setAlpha:1.0];
										  }];
					 }];
	
	[UIView animateWithDuration:0.15
					 animations:^{
						 [_switchButton setAlpha:0.0];
						 [_fImageView setAlpha:0.0];
					 }];
	
	[UIViewController attemptRotationToDeviceOrientation];
}

- (void)flashButtonPressed:(id)sender {
	_flashMode = _flashMode==RAFlashModeOff?RAFlashModeAuto:_flashMode+1;
	
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
	[_fImageView setImage:_flashImage[_flashMode]];
	[self.cameraController setCameraFlashMode:cameraFlashMode];
}

@end

//--------------------------------------------------------------------------------------------------------------
#pragma mark - RAFlashView -
//--------------------------------------------------------------------------------------------------------------

static CGRect RAResizedFrameWithFactor(CGRect frame, CGFloat factor)
{
	CGSize fsize = CGSizeMake(frame.size.width*factor, frame.size.height*factor);
	return CGRectMake(frame.origin.x - (fsize.width - frame.size.width)/2, frame.origin.y - (fsize.height - frame.size.height)/2, fsize.width, fsize.height);
}

static RAFlashMode RAFlashModeFromLocation(CGPoint location)
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
	CGAffineTransform _orientationTransform;
	
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

		_flashImage = [[UIImageView alloc] initWithImage:[UIImage RAImageNamed:@"RACC_flash"]];
		[_flashImage setCenter:CGPointMake(16.0, 23.0)];
		[self addSubview:_flashImage];
		_modeLabel[RAFlashModeOff] = [self modeLabelWithText:@"O f f"];
		[_modeLabel[RAFlashModeOff] setAlpha:0.0];
		[self addSubview:_modeLabel[RAFlashModeOff]];
		_modeLabel[RAFlashModeOn] = [self modeLabelWithText:@"O n"];
		[_modeLabel[RAFlashModeOn] setAlpha:0.0];
		[self addSubview:_modeLabel[RAFlashModeOn]];
		_modeLabel[RAFlashModeAuto] = [self modeLabelWithText:@"A u t o"];
		[self addSubview:_modeLabel[RAFlashModeAuto]];
		
		_orientationTransform = CGAffineTransformIdentity;
	}
    return self;
}

- (UILabel *)modeLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(28.0, 16.0, 50.0, 11.0)];
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
	
	_orientationTransform = CGAffineTransformMakeRotation(angle);
	
	[_modeLabel[RAFlashModeAuto] setTransform:_orientationTransform];
	[_modeLabel[RAFlashModeOn] setTransform:_orientationTransform];
	[_modeLabel[RAFlashModeOff] setTransform:_orientationTransform];
	[_flashImage setTransform:_orientationTransform];
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
	tFlashModeOn = CGAffineTransformConcat(_orientationTransform,tFlashModeOn);
	CGAffineTransform tFlashModeOff = CGAffineTransformMakeTranslation(105.0, 0.0);
	tFlashModeOff = CGAffineTransformConcat(_orientationTransform,tFlashModeOff);
	
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
		[_modeLabel[RAFlashModeOn] setTransform:_orientationTransform];
		[_modeLabel[RAFlashModeOff] setTransform:_orientationTransform];
	}];
}

@end
