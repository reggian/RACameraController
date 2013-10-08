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

#pragma mark - UIImagePickerController RAExtension -

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

#pragma mark - RACameraOverlayView Subclasses -

@interface RACameraOverlayView7 : RACameraOverlayView
@end

#pragma mark - RACameraController -

@interface RACameraController ()

@end

@implementation RACameraController

- (id)init
{
    self = [super init];
    if (self) {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			_imagePickerController = [[UIImagePickerController alloc] init];
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
		[_imagePickerController.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
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

@end

#pragma mark - RACameraOverlayView -

@implementation RACameraOverlayView

- (instancetype)initWithCameraController:(RACameraController *)controller
{
	CGRect frame = [[UIScreen mainScreen] bounds];
    self = [super initWithFrame:frame];
    if (self)
	{
		_cameraController = controller;
		[self setTintColor:[UIColor whiteColor]];
        [self setup];
    }
    return self;
}

- (void)setup{}

@end

#pragma mark - RACameraOverlayView7

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

@end

#pragma mark - RAFlashView -

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
	
	RAFlashMode _flashMode;
	RAFlashMode _hlFlashMode;
	CGRect _hitFrame;
	BOOL _highlighted;
	BOOL _expanded;
	
	NSTimer *_collapseTimer;
}

- (instancetype)initWithCameraOverlayView:(RACameraOverlayView *)cameraOverlayView
{
	CGRect frame = CGRectMake(0.0, 0.0, 80.0, 60.0);
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
	[self setFrame:CGRectMake(0.0, 0.0, 160.0, 60.0)];
	[UIView animateWithDuration:0.2
					 animations:^{
						 [_modeLabel[RAFlashModeAuto] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOn] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOff] setAlpha:1.0];
						 [_modeLabel[RAFlashModeOn] setTransform:CGAffineTransformMakeTranslation(60.0, 0.0)];
						 [_modeLabel[RAFlashModeOff] setTransform:CGAffineTransformMakeTranslation(105.0, 0.0)];
					 }];
}

- (void)collapse
{
	[self collapseWithFlashMode:_flashMode];
}

- (void)collapseWithFlashMode:(RAFlashMode)flashMode
{
	_expanded = NO;
	[self setFrame:CGRectMake(0.0, 0.0, 80.0, 60.0)];

	[UIView animateWithDuration:0.2 animations:^{
		for (RAFlashMode fm = 0; fm < RAFlashModes; fm++)
		{
			[_modeLabel[fm] setAlpha:(fm == flashMode?1.0:0.0)];
		}
		[_modeLabel[RAFlashModeOn] setTransform:CGAffineTransformIdentity];
		[_modeLabel[RAFlashModeOff] setTransform:CGAffineTransformIdentity];
	}];
}

@end
