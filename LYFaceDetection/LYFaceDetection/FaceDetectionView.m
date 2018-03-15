//
//  FaceDetectionView.m
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//
#import <AVFoundation/AVUtilities.h>
#import <GLKit/GLKit.h>
#import "FaceDetectionView.h"
#import "FaceDetectionView.h"
#import "LYShaderManager.h"
#import "LYFaceDetector.h"

// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_ROTATE_MATRIX,
    UNIFORM_TEMP_INPUT_IMG_TEXTURE,
    NUM_UNIFORMS
};
static GLint glViewUniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    ATTRIB_TEMP_VERTEX,
    ATTRIB_TEMP_TEXCOORD,
    NUM_ATTRIBUTES
};
static GLint glViewAttributes[NUM_ATTRIBUTES];

@interface FaceDetectionView() {
    GLint _backingWidth;
    GLint _backingHeight;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    dispatch_semaphore_t _lock;
}


@property (nonatomic, weak) CAEAGLLayer *eaglLayer;

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, strong) LYShaderManager *shaderManager;

@property (nonatomic, strong) LYShaderManager *textureManager;

@property (nonatomic, assign) GLuint frameBuffer;

@property (nonatomic, assign) GLuint renderBuffer;

@property (nonatomic, assign) GLuint myTexture;

@end

@implementation FaceDetectionView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _initialSetup];
    }
    return self;
}

- (void)_initialSetup {
    _lock = dispatch_semaphore_create(1);
    [self setupLayer];
    [self setupContext];
    [self loadShaders];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    _myTexture = [self setupTexture:@"test.jpg"];
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

- (void)dealloc
{
    [self cleanUpTextures];
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}

- (void)setupLayer {
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    self.eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(NO),kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
    self.eaglLayer.opaque = true;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"initialize failed");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"failed to setCurrentContext");
        exit(1);
    }
}

- (void)loadShaders {
    //一定要设置视口大小
    CGFloat scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    self.shaderManager = [[LYShaderManager alloc] initWithVertexShaderFileName:@"FaceDetectionShader" fragmentFileName:@"FaceDetectionShader"];
    glViewAttributes[ATTRIB_VERTEX] = [self.shaderManager getAttributeLocation:"aPosition"];
    glViewAttributes[ATTRIB_TEXCOORD] = [self.shaderManager getAttributeLocation:"aTexCoordinate"];
    glViewUniforms[UNIFORM_Y] = [self.shaderManager getUniformLocation:"SamplerY"];
    glViewUniforms[UNIFORM_UV] = [self.shaderManager getUniformLocation:"SamplerUV"];
    glViewUniforms[UNIFORM_ROTATE_MATRIX] = [self.shaderManager getUniformLocation:"rotateMatrix"];
    
    self.textureManager = [[LYShaderManager alloc] initWithVertexShaderFileName:@"FaceTextureShader" fragmentFileName:@"FaceTextureShader"];
    glViewAttributes[ATTRIB_TEMP_VERTEX] = [self.textureManager getAttributeLocation:"aPosition"];
    glViewAttributes[ATTRIB_TEMP_TEXCOORD] = [self.textureManager getAttributeLocation:"aTexCoordinate"];
    glViewUniforms[UNIFORM_TEMP_INPUT_IMG_TEXTURE] = [self.textureManager getUniformLocation:"inputTexture"];
    
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef context = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM (context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(context);
    
    GLuint texture;
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int32_t)width, (int32_t)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return texture;
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer != NULL) {
        
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!_videoTextureCache) {
            NSLog(@"NO Video Texture Cache");
            return;
        }
        if ([EAGLContext currentContext] != _context) {
            [EAGLContext setCurrentContext:_context];
        }
        
        [self cleanUpTextures];
        
        glActiveTexture(GL_TEXTURE0);
        
        CVReturn err;
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RED_EXT,
                                                           width,
                                                           height,
                                                           GL_RED_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           width / 2,
                                                           height / 2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        glViewport(0, 0, _backingWidth, _backingHeight);
        
    }
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    [self.shaderManager useProgram];
    glUniform1i(glViewUniforms[UNIFORM_Y], 0);
    glUniform1i(glViewUniforms[UNIFORM_UV], 1);
    
    glUniformMatrix4fv(glViewUniforms[UNIFORM_ROTATE_MATRIX], 1, GL_FALSE, GLKMatrix4MakeXRotation(M_PI).m);
    
    GLfloat quadVertexData[] = {
        -1, -1,
        1, -1 ,
        -1, 1,
        1, 1,
    };
    
    // 更新顶点数据
    glVertexAttribPointer(glViewAttributes[ATTRIB_VERTEX], 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(glViewAttributes[ATTRIB_VERTEX]);
    
    GLfloat quadTextureData[] =  { // 正常坐标
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    glVertexAttribPointer(glViewAttributes[ATTRIB_TEXCOORD], 2, GL_FLOAT, GL_FALSE, 0, quadTextureData);
    glEnableVertexAttribArray(glViewAttributes[ATTRIB_TEXCOORD]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [LYFaceDetector detectCVPixelBuffer:pixelBuffer completionHandler:^(CIFaceFeature *result, CIImage *ciImage) {
        if (result) {
            [self renderTempTexture:result ciImage:ciImage];
        }
    }];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    if ([EAGLContext currentContext] == _context) {
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (void)renderTempTexture:(CIFaceFeature *)faceFeature ciImage:(CIImage *)ciImage {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    //得到图片的尺寸
    CGSize ciImageSize = [ciImage extent].size;
    //初始化transform
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
    transform = CGAffineTransformTranslate(transform,0,-ciImageSize.height);
    // 实现坐标转换
    CGSize viewSize =self.layer.bounds.size;
    CGFloat scale = MIN(viewSize.width / ciImageSize.width,viewSize.height / ciImageSize.height);
    
    CGFloat offsetX = (viewSize.width - ciImageSize.width * scale) / 2;
    CGFloat offsetY = (viewSize.height - ciImageSize.height * scale) / 2;
    // 缩放
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    //获取人脸的frame
    CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
    // 修正
    faceViewBounds = CGRectApplyAffineTransform(faceViewBounds,scaleTransform);
    faceViewBounds.origin.x += offsetX;
    faceViewBounds.origin.y += offsetY;
    
    
    NSLog(@"face frame after:%@",NSStringFromCGRect(faceViewBounds));
    [self.textureManager useProgram];
    glBindTexture(GL_TEXTURE_2D, _myTexture);
    glUniform1i(glViewUniforms[UNIFORM_TEMP_INPUT_IMG_TEXTURE], 2);
    
    CGFloat midX = CGRectGetMidX(self.layer.bounds);
    CGFloat midY = CGRectGetMidY(self.layer.bounds);
    
    CGFloat originX = CGRectGetMinX(faceViewBounds);
    CGFloat originY = CGRectGetMinY(faceViewBounds);
    CGFloat maxX = CGRectGetMaxX(faceViewBounds);
    CGFloat maxY = CGRectGetMaxY(faceViewBounds);
    
    //贴图顶点
    GLfloat minVertexX = (originX - midX) / midX;
    GLfloat minVertexY = (midY - maxY) / midY;
    GLfloat maxVertexX = (maxX - midX) / midX;
    GLfloat maxVertexY = (midY - originY) / midY;
    GLfloat quadData[] = {
        minVertexX, minVertexY,
        maxVertexX, minVertexY,
        minVertexX, maxVertexY,
        maxVertexX, maxVertexY,
    };
    
    glVertexAttribPointer(glViewAttributes[ATTRIB_TEMP_VERTEX], 2, GL_FLOAT, GL_FALSE, 0, quadData);
    glEnableVertexAttribArray(glViewAttributes[ATTRIB_TEMP_VERTEX]);
    
    GLfloat quadTextureData[] =  { // 正常坐标
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    glVertexAttribPointer(glViewAttributes[ATTRIB_TEMP_TEXCOORD], 2, GL_FLOAT, GL_FALSE, 0, quadTextureData);
    glEnableVertexAttribArray(glViewAttributes[ATTRIB_TEMP_TEXCOORD]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    dispatch_semaphore_signal(_lock);
}

- (UIImage *)snapshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)cleanUpTextures {
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

@end
