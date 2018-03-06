//
//  LYShaderManager.h
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>

@interface LYShaderManager : NSObject

@property (nonatomic, assign) GLuint program;

- (instancetype)initWithVertexShaderFileName:(NSString *)vertexFileName fragmentFileName:(NSString *)fragmentFileName;

- (GLint)getUniformLocation:(const GLchar*) name;

- (GLuint)getAttributeLocation:(const GLchar *)name;

- (void)useProgram;

@end
