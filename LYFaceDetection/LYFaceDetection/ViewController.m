//
//  ViewController.m
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"
#import "FaceDetectionView.h"
#import "LYCameraManager.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) LYCameraManager *cameraManager;
@property (weak, nonatomic) IBOutlet FaceDetectionView *faceDetectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startCapture];
}

- (IBAction)startCapture {
    self.cameraManager = [LYCameraManager cameraManagerWithSampleBufferDelegate:self];
}

- (IBAction)switchCamera {
    if (!self.cameraManager) { return; }
    [self.cameraManager switchCamera];
}

- (IBAction)screenshot {
    if (!self.cameraManager) { return; }
    UIGraphicsBeginImageContext(self.view.frame.size);
    [self.faceDetectionView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) {
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (authStatus == ALAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied){
            //无权限
            return;
        }
        [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                NSLog(@"图片保存成功");
            }
        }];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.faceDetectionView displayPixelBuffer:pixelBuffer];
    
}

@end
