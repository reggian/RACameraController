//
//  ViewController.m
//  CameraControllerExample
//
//  Created by Andreas de Reggi on 07. 10. 2013.
//  Copyright (c) 2013 Nollie Apps. All rights reserved.
//

#import "ViewController.h"
#import "RACameraController.h"

@interface ViewController ()
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIButton *button;
@property (nonatomic, strong) RACameraController *cameraController;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.cameraController = [[RACameraController alloc] init];
	if (_cameraController.imagePickerController)
	{
		[_cameraController.imagePickerController setDelegate:self];
	}
	else
	{
		[[[UIAlertView alloc] initWithTitle:@"No Camera"
									message:@"Your device does not support this option."
								   delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil] show];
		[_button setTitle:@"No Camera" forState:UIControlStateNormal];
		[_button setEnabled:NO];
	}
}

- (IBAction)buttonPressed:(id)sender
{
	[self presentViewController:_cameraController.imagePickerController animated:YES completion:NULL];
}

#pragma mark - UIImagePickerDelegate Methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	[_imageView setImage:image];
}

@end
