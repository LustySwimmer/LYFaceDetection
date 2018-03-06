//
//  LYCameraManager.m
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import "LYCameraManager.h"

@interface LYCameraManager() {
    dispatch_queue_t processQueue;
}


@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;

@end

@implementation LYCameraManager

+ (instancetype)cameraManagerWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate {
    return [[self alloc] initWithSampleBufferDelegate:delegate];
}

- (instancetype)initWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate {
    if (self = [super init]) {
        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        
        AVCaptureDevice *captureDevice = nil;
        NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in captureDevices) {
            if (device.position == AVCaptureDevicePositionBack) {
                captureDevice = device;
                break;
            }
        }
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
        
        if ([self.captureSession canAddInput:self.captureDeviceInput]) {
            [self.captureSession addInput:self.captureDeviceInput];
        }
        
        self.captureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
        [self.captureDeviceOutput setAlwaysDiscardsLateVideoFrames:YES];
        
        processQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        [self.captureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [self.captureDeviceOutput setSampleBufferDelegate:delegate queue:processQueue];
        
        if ([self.captureSession canAddOutput:self.captureDeviceOutput]) {
            [self.captureSession addOutput:self.captureDeviceOutput];
        }
        
        AVCaptureConnection *captureConnection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
        [captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
        [self.captureSession startRunning];
    }
    return self;
}

- (void)switchCamera {
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[self.captureDeviceInput device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        if (newInput != nil) {
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:self.captureDeviceInput];
            if ([self.captureSession canAddInput:newInput]) {
                [self.captureSession addInput:newInput];
                self.captureDeviceInput = newInput;
            }else {
                [self.captureSession addInput:self.captureDeviceInput];
            }
            AVCaptureConnection *captureConnection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
            [captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            [self.captureSession commitConfiguration];
        }
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

@end
