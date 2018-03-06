varying lowp vec2 texCoordVarying;

uniform sampler2D inputTexture;

void main()
{
    gl_FragColor = texture2D(inputTexture, texCoordVarying);
}
