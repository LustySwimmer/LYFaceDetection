attribute vec4 aPosition;
attribute vec2 aTexCoordinate;

varying lowp vec2 texCoordVarying;

void main()
{
    texCoordVarying = aTexCoordinate;
    gl_Position = aPosition;
}
