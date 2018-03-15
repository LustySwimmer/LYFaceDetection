//
//  LYFaceDetector.m
//  OpenGLESPracticeDemo
//
//  Created by LustySwimmer on 2018/1/18.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import "LYFaceDetector.h"

@implementation LYFaceDetector

+ (void)detectCVPixelBuffer:(CVPixelBufferRef)pixelBuffer completionHandler:(void (^)(CIFaceFeature *, CIImage *))completion {
    if (pixelBuffer) {
//        [[CIImage alloc] initWithImage:image];
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        NSString *accuracy = CIDetectorAccuracyLow;
        NSDictionary *options = [NSDictionary dictionaryWithObject:accuracy forKey:CIDetectorAccuracy];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
        NSArray *featuresArray = [detector featuresInImage:ciImage options:nil];
        CIFaceFeature *choosenFaceFeature = [self bestFaceFeaturesInFeatherArray:featuresArray];
        !completion ?: completion(choosenFaceFeature,ciImage);
    } else {
        !completion ?: completion(nil, nil);
    }
}

+ (CIFaceFeature *)bestFaceFeaturesInFeatherArray:(NSArray *)featureArray {
    //get the bestFaceFeature by the maxnum bounds Square size
    CGFloat maxFaceSquare = 0.0;
    CIFaceFeature * chooseFaceFeature = nil;
    for (CIFaceFeature * faceFeathre in featureArray) {
        CGRect bounds = faceFeathre.bounds;
        CGFloat currentFaceSqu = CGRectGetWidth(bounds)*CGRectGetHeight(bounds);
        if (currentFaceSqu > maxFaceSquare) {
            maxFaceSquare = currentFaceSqu;
            chooseFaceFeature = faceFeathre;
        }
    }
    return chooseFaceFeature;
}

@end
