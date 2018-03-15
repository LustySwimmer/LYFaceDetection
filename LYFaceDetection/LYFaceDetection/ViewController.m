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
    [self animationCamera];
}

- (IBAction)screenshot {
    if (!self.cameraManager) { return; }
    UIImage *image = [self.faceDetectionView snapshot];
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

- (void)animationCamera {
    CATransition *animation = [CATransition animation];
    animation.duration = .5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"oglFlip";
    animation.subtype = kCATransitionFromRight;
    [self.faceDetectionView.layer addAnimation:animation forKey:nil];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.faceDetectionView displayPixelBuffer:pixelBuffer];
    
}

@end
