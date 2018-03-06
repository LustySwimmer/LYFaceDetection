attribute vec4 aPosition;
attribute vec2 aTexCoordinate;

varying lowp vec2 texCoordVarying;

uniform mat4 rotateMatrix;

void main()
{
    texCoordVarying = aTexCoordinate;
    gl_Position = rotateMatrix * aPosition;
}
