//
//  LYShaderManager.m
//  LYFaceDetection
//
//  Created by LustySwimmer on 2018/3/6.
//  Copyright © 2018年 LustySwimmer. All rights reserved.
//

#import "LYShaderManager.h"

@implementation LYShaderManager

- (instancetype)initWithVertexShaderFileName:(NSString *)vertexFileName fragmentFileName:(NSString *)fragmentFileName {
    if (self = [super init]) {
        self.program = glCreateProgram();
        NSURL *vertexPath = [[NSBundle mainBundle] URLForResource:vertexFileName withExtension:@"vsh"];
        NSURL *fragmentPath = [[NSBundle mainBundle] URLForResource:fragmentFileName withExtension:@"fsh"];
        [self compileShadersWithVertexFile:vertexPath fragmentFile:fragmentPath];
    }
    return self;
}

- (void)compileShadersWithVertexFile:(NSURL *)vertexPath fragmentFile:(NSURL *)fragmentPath {
    GLuint vertexShader, fragmentShader;
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER URL:vertexPath] || ![self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER URL:fragmentPath]) {
        return;
    }
    if (![self linkProgram]) {
        [self deleteShader:&vertexShader];
        [self deleteShader:&fragmentShader];
        return;
    }
    [self detachAndDeleteShader:&vertexShader];
    [self detachAndDeleteShader:&fragmentShader];
    [self useProgram];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    // 编译成功后，吸附到程序中去
    glAttachShader(self.program, *shader);
    
    return YES;
}

- (BOOL)linkProgram
{
    GLint status;
    glLinkProgram(_program);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram
{
    GLint logLength, status;
    
    glValidateProgram(_program);
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(_program, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)bindAttribLocation:(GLuint)index andAttribName:(GLchar*)name{
    glBindAttribLocation(self.program, index, name);
    
}

- (void)deleteShader:(GLuint*)shader{
    if (*shader){
        glDeleteShader(*shader);
        *shader = 0;
    }
}

- (GLint)getUniformLocation:(const GLchar*) name{
    return  glGetUniformLocation(self.program, name);
}

- (GLuint)getAttributeLocation:(const GLchar *)name {
    return glGetAttribLocation(self.program, name);
}

-(void)detachAndDeleteShader:(GLuint *)shader{
    if (*shader){
        glDetachShader(self.program, *shader);
        glDeleteShader(*shader);
        *shader = 0;
    }
}

-(void)deleteProgram{
    if (self.program){
        glDeleteProgram(self.program);
        self.program = 0;
    }
}

-(void)useProgram{
    glUseProgram(self.program);
}

-(void)dealloc{
    [self deleteProgram];
}

@end
