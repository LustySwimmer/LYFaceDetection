//
//  LYFaceDetector.h
//  OpenGLESPracticeDemo
//
//  Created by LustySwimmer on 2018/1/18.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LYFaceDetector : NSObject

+ (void)detectCVPixelBuffer:(CVPixelBufferRef)pixelBuffer completionHandler:(void(^)(CIFaceFeature *result, CIImage *ciImage))completion;

@end
