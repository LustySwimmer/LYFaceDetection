# LYFaceDetection
A sample to recognize face with CoreImage and display based on OpenGL <br/>
![FaceDetection](https://github.com/LustySwimmer/LYFaceDetection/blob/master/FaceDetection.gif) <br/>
You can get the result image use snapshot method in FaceDetectionView and save it to your iPhone
```
UIImage *image = [self.faceDetectionView snapshot];
    if (image) {
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (authStatus == ALAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied){
            //无权限
            return;
        }
        [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                NSLog(@"Image saved succeed");
            }
        }];
    }
```

# 这是一个利用CoreImage和OpenGL实现的人脸识别的demo
更多详细的介绍请访问底部博客链接：<br/>
[More details in blog](https://www.jianshu.com/p/028af518c781)
