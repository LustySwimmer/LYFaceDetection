//
//  LYCameraManager.h
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LYCameraManager : NSObject

+ (instancetype)cameraManagerWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate;

- (void)switchCamera;

@end
