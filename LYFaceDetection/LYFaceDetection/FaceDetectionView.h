//
//  FaceDetectionView.h
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FaceDetectionView : UIView

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (UIImage *)snapshot;

@end
