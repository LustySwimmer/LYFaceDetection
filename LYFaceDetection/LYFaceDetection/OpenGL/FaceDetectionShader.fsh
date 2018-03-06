varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;

void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    mediump mat3 convert = mat3(1.164,  1.164, 1.164,
                                0.0, -0.213, 2.112,
                                1.793, -0.533,   0.0);
    // Subtract constants to map the video range start at 0
    yuv.x = (texture2D(SamplerY, texCoordVarying).r);// - (16.0/255.0));
    yuv.yz = (texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5));
    
    rgb = convert * yuv;
    
    gl_FragColor = vec4(rgb,1);
    
}
